# encoding: UTF-8
require 'pry'

module Sinatra
    module ResumesRoutes
        def self.registered(app)
            app.get '/resumes/unapproved' do
              users = User.all(approved_resume: false, order: [ :netid.desc ])
              result = []
              users.each do |user|
                url = AWS.fetch_resume(user.netid)
                result << {
                  "firstName": user.first_name,
                  "lastName": user.last_name,
                  "netid": user.netid,
                  "dateJoined": user.date_joined,
                  "resume": url
                }
              end
              
              ResponseFormat.format_response(result, request.accept)
            end
            
            app.put '/resume_status' do
              string = request.body.read.gsub(/=>/, ":")
              payload = JSON.parse(string)
              
              return [400, "Missing netid"] unless payload["netid"]
              return [400, "Missing resume status"] unless payload["resume_status"]
              
              user = User.first(netid: payload["netid"])
              
              return [400, "User not found"] unless user
              return [400, "Resume already approved"] if user.approved_resume
              
              if payload["resume_status"]
                user.update(approved_resume: true)
              else
                # Delete resume and user
                AWS.delete_resume(user.netid)
                
                halt 500 unless user.destroy
              end
              return [200, "OK"]
            end
          
            app.post '/resume' do
                string = request.body.read.gsub(/=>/, ":")
                payload = JSON.parse(string)

                return [400, "Missing firstName"] unless payload["firstName"]
                return [400, "Missing lastName"] unless payload["lastName"]
                return [400, "Missing netid"] unless payload["netid"]
                return [400, "Missing resume"] unless payload["resume"]
                valid = User.is_valid_user?(payload["firstName"], payload["lastName"], payload["netid"])
                if valid
                    user = (User.first_or_create(
                        {
                            netid: payload["netid"]
                        },{
                            first_name: payload["firstName"].capitalize,
                            last_name: payload["lastName"].capitalize,
                            netid: payload["netid"],
                            date_joined: Time.now.getutc
                        }
                    ))
                    
                    successful_upload = AWS.upload_resume(payload["netid"], payload["resume"])
                    return [400, "Error uploading resume to S3"] unless successful_upload
                    
                    user.approved_resume = false
                    user.save!
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
