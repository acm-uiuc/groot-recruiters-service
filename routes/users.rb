# encoding: UTF-8
module Sinatra
    module UsersRoutes
        def self.registered(app)
            app.get '/' do
                "This is the groot users service"
            end

            app.get '/users' do
                ResponseFormat.format_response(User.all(order: [ :netid.desc ]), request.accept)
            end

            app.get '/users/:netid' do
                user ||= User.first(netid: params[:netid]) || halt(404)
                ResponseFormat.format_response(user, request.accept)
            end
            
            app.get '/users/search' do
              graduation_start = payload["graduation_start"] # YYYY-MM-DD
              graduation_end = payload["graduation_end"] # YYYY-MM-DD
              level = payload["level"] # Undergraduate, Masters, PHD
              seeking = payload["seeking"] # Internship (co-op), or Full time
              
              num_per_page = payload["num_per_page"]
              page = payload["page"]
            end

            app.put '/users/:netid' do
                payload = JSON.parse(request.body.read)
                
                first_name = payload["firstName"]
                last_name = payload["lastName"]
                netid = payload["netid"]
                email = payload["email"]
                graduation_date = payload["gradYear"]
                degree_type = payload["degreeType"]
                job_type = payload["jobType"]
                
                return [400, "Missing first_name"] unless first_name
                return [400, "Missing netid"] unless netid
                return [400, "Missing email"] unless email
                return [400, "Missing grad_year"] unless graduation_date
                return [400, "Missing degree_type"] unless degree_type
                return [400, "Missing job_type"] unless job_type
                
                user ||= User.first(netid: netid) || halt(404)
                halt 500 unless user.update(
                    first_name: first_name,
                    last_name: last_name,
                    netid: netid,
                    email: email,
                    graduation_date: graduation_date,
                    degree_type: degree_type,
                    job_type: job_type,
                    date_joined: Time.now.getutc
                )
                return [status, ResponseFormat.format_response(quote, request.accept)]
            end

            app.delete '/users/:id' do
                user ||= User.first(netid: params[:netid]) || halt(404)
                AWS.delete_resume(user.netid)
                
                halt 500 unless user.destroy
            end
        end
    end
    register UsersRoutes
end
