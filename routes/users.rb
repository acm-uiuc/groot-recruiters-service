# encoding: UTF-8
require 'date'
require 'pry'
require 'net/http'

module Sinatra
    module UsersRoutes
        def self.registered(app)
            app.get '/' do
                "This is the groot users service"
            end

            app.get '/users' do
                ResponseFormat.format_response(User.all(order: [ :netid.desc ]), request.accept)
            end
            
            app.get '/users/search' do
              string = request.body.read.gsub(/=>/, ":")
              payload = JSON.parse(string)
              
              graduation_start = payload["graduation_start"] # YYYY-MM-DD
              graduation_end = payload["graduation_end"] # YYYY-MM-DD
              
              graduation_start_date = DateTime.parse(graduation_start) if graduation_start
              graduation_end_date = DateTime.parse(graduation_end) if graduation_end
              
              netid = payload["netid"]
              level = payload["level"] # Undergraduate, Masters, PHD
              seeking = payload["seeking"] # Internship (co-op), or Full time
              
              num_per_page = payload["page"].to_i if payload["num_per_page"] && payload["num_per_page"].match(/^\d+$/)
              page = (payload["page"] && payload["page"].match(/^\d+$/)) ? payload["page"].to_i : 1
              
              return [400, "Invalid page"] if page <= 0
              
              conditions = {}
              conditions[:netid] = netid if netid
              conditions[:"graduation_date.gt"] = graduation_start_date if graduation_start_date
              conditions[:"graduation_date.lt"] = graduation_end_date if graduation_end_date
              conditions[:level] = level if level
              conditions[:job_type] = seeking if seeking
              
              matching_users = User.all(conditions)
              
              num_per_page ||= 50
              page ||= 1
              start = (page - 1) * num_per_page
              
              response = []
              matching_users[start..start + num_per_page].each do |user|
                netid = user["netid"]
                user_json = JSON.parse(user.to_json)
                
                # # TODO change URL - talk to crowd?
                # url = URI.parse("http://localhost:8000/user?username=#{netid}")
                # req = Net::HTTP::Get.new(url.to_s)
                # res = Net::HTTP.start(url.host, url.port) { |http|
                #   http.request(req)
                # }
                # user_json["is_acm_member"] = JSON.parse(res.body)["Text"] != "404 Not Found"
                
                response << user_json
              end
              
              response[:next_page] = page + 1 if start + num_per_page < matching_users.count
              response[:previous_page] = page - 1 if page > 1 and response[:users].count != 0 
              
              ResponseFormat.format_response(response, request.accept)
            end

            app.get '/users/:netid' do
                user ||= User.first(netid: params[:netid]) || halt(404)
                ResponseFormat.format_response(user, request.accept)
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
                
                graduation_date_obj = DateTime.parse(graduation_date)
                
                user ||= User.first(netid: netid) || halt(404)
                halt 500 unless user.update(
                    first_name: first_name,
                    last_name: last_name,
                    netid: netid,
                    email: email,
                    graduation_date: graduation_date_obj,
                    degree_type: degree_type,
                    job_type: job_type,
                    date_joined: Time.now.getutc
                )
                return [status, ResponseFormat.format_response(quote, request.accept)]
            end

            app.delete '/users/:netid' do
                user ||= User.first(netid: params[:netid]) || halt(404)
                AWS.delete_resume(user.netid)
                
                halt 500 unless user.destroy
            end
        end
    end
    register UsersRoutes
end
