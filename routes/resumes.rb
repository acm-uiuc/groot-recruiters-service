# encoding: UTF-8
module Sinatra
    module ResumesRoutes
        def self.registered(app)
            app.post '/resume' do
                string = request.body.read.gsub(/=>/, ":")
                payload = JSON.parse(string)

                return [400, "Missing firstName"] unless payload["firstName"]
                return [400, "Missing netid"] unless payload["netid"]
                return [400, "Missing lastName"] unless payload["lastName"]
                return [400, "Missing resume"] unless payload["resume"]
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
                    
                    successful_upload = AWS.upload_resume(payload["netid"], payload["resume"])
                    return [400, "Error uploading resume to S3"] unless successful_upload
                end
                status = valid ? 200 : 403
                return [status, ResponseFormat.format_response(user, request.accept)]
            end
            
            app.delete '/resume' do
              string = request.body.read.gsub(/=>/, ":")
              payload = JSON.parse(string)
              
              return [400, "Missing netid"] unless payload["netid"]
              
              successful_delete = AWS.delete_resume(payload["netid"])
              return [400, "Error uploading resume with netid #{payload['netid']} to S3"] unless successful_delete
              
              return [200, "OK"]
            end
        end
    end
    register ResumesRoutes
end
