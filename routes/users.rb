# encoding: UTF-8
require 'aws/s3'
require 'base64'
require 'tempfile'

class GrootRecruiterService < Sinatra::Application
    aws = Config.config("aws")

    get '/' do
        "This is the groot users service"
    end

    get '/users' do
        format_response(User.all(order: [ :netid.desc ]), request.accept)
    end

    get '/users/:netid' do
        user ||= User.first(netid: params[:netid]) || halt(404)
        puts user.inspect
        format_response(user, request.accept)
    end

    post '/users' do
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

            # Upload to S3
            AWS::S3::Base.establish_connection!(
              access_key_id: aws["access_key_id"],
              secret_access_key: aws["secret_access_key"]
            )

            temp_file = Tempfile.new(['foo', '.pdf'])
            File.open(temp_file, 'wb') {|f| f.write(Base64.decode64(payload["resume"]))}
            puts temp_file.path
            AWS::S3::S3Object.store(payload["netid"]+".pdf", File.read(temp_file.path), 'groot-recruiters-service-fs/resumes1', content_type: 'application/pdf')
        end
        status = valid ? 200 : 403
        return [status,format_response(user, request.accept)]
    end

    put '/users/:netid' do
        payload = JSON.parse(request.body.read)
        return [400, "Missing first_name"] unless payload["first_name"]
        return [400, "Missing netid"] unless payload["netid"]
        return [400, "Missing last_name"] unless payload["last_name"]
        user ||= User.first(netid: params[:netid]) || halt(404)
        halt 500 unless user.update(
            first_name: payload["first_name"],
            last_name: payload["last_name"],
            netid: payload["netid"],
        )
        return [status,format_response(quote, request.accept)]
    end

    delete '/users/:id' do
        user ||= User.first(netid: params[:netid]) || halt(404)
        halt 500 unless user.destroy
    end
end
