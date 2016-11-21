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
            
            app.put '/resumes/approve' do              
              return [400, "Missing netid"] unless params["netid"]
              
              user = User.first(netid: params["netid"])
              
              return [400, "User not found"] unless user
              return [400, "Resume already approved"] if user.approved_resume
              
              if params["resume_status"]
                user.update(approved_resume: true)
              else
                # Delete resume and user
                AWS.delete_resume(user.netid)
                
                halt 500 unless user.destroy
              end
              
              200
            end
          
            app.post '/resumes' do
                first_name = params["firstName"]
                last_name = params["lastName"]
                netid = params["netid"]
                email = params["email"]
                graduation_date = params["gradYear"]
                degree_type = params["degreeType"]
                job_type = params["jobType"]
                resume = params["resume"]
                
                return [400, "Missing first_name"] unless first_name
                return [400, "Missing netid"] unless netid
                return [400, "Missing email"] unless email
                return [400, "Missing grad_year"] unless graduation_date
                return [400, "Missing degree_type"] unless degree_type
                return [400, "Missing job_type"] unless job_type
                
                valid = User.is_valid_user?(first_name, last_name, netid)
                if valid
                  user = (User.first_or_create(
                      {
                          netid: netid
                      },{
                          first_name: first_name.capitalize,
                          last_name: last_name.capitalize,
                          netid: netid,
                          email: email,
                          graduation_date: graduation_date,
                          degree_type: degree_type,
                          job_type: job_type,
                          date_joined: Time.now.getutc
                      }
                    ))
                    
                    successful_upload = AWS.upload_resume(params["netid"], params["resume"])
                    return [400, "Error uploading resume to S3"] unless successful_upload
                    
                    user.approved_resume = false
                    user.save!
                end
                status = valid ? 200 : 403
                return [status, ResponseFormat.format_response(user, request.accept)]
            end
            
            app.delete '/resumes' do
              return [400, "Missing netid"] unless params["netid"]
              
              successful_delete = AWS.delete_resume(params["netid"])
              return [400, "Error deleting resume with netid #{params['netid']} to S3"] unless successful_delete
              
              200
            end
        end
    end
    register ResumesRoutes
end
