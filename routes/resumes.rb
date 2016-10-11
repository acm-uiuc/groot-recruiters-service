# encoding: UTF-8
require 'aws/s3'
require 'base64'
require 'tempfile'

module Sinatra
    module ResumesRoutes
        def self.registered(app)
            app.post '/resume' do
                string = request.body.read.gsub(/=>/, ":")
                payload = JSON.parse (string || '{"name":"Not Given"}')

                return [400, "Missing firstName"] unless payload["firstName"]
                return [400, "Missing netid"] unless payload["netid"]
                return [400, "Missing lastName"] unless payload["lastName"]
                valid = User.is_valid_user?(payload["firstName"], payload["lastName"], payload["netid"])
                puts valid
                user = ""
                if valid
                    user = (User.first_or_create(
                        {
                            netid: payload["netid"]
                        },{
                            first_name: payload["firstName"],
                            last_name: payload["lastName"],
                            netid: payload["netid"],
                            date_joined: Time.now.getutc
                        }
                    ))

                    aws = Config.load_config("aws")
                    # Upload to S3
                    AWS::S3::Base.establish_connection!(
                      access_key_id: aws["access_key_id"],
                      secret_access_key: aws["secret_access_key"]
                    )

                    buffer = JSONBase64Decoder.decode(payload["resume"])

                    #TODO change foo to some generatable string (i.e. netid+timestamp)
                    temp_file = Tempfile.new(['foo', '.pdf'])
                    File.open(temp_file, 'wb') {|f| f.write(Base64.decode64(buffer["data"]))}
                    puts temp_file.path
                    AWS::S3::S3Object.store(payload["netid"]+".pdf", File.read(temp_file.path), 'groot-recruiters-service-fs/resumes1', content_type: 'application/pdf')
                end
                status = valid ? 200 : 403
                return [status, ResponseFormat.format_response(user, request.accept)]
            end
        end
    end
    register ResumesRoutes
end
