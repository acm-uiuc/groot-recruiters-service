# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
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
            
            # HANDLE CORS
            app.options "*" do
              response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
              response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept, Origin, Access-Control-Allow-Origin"
              response.headers["Access-Control-Allow-Origin"] = "*"
              200
            end

            app.get '/users' do
              ResponseFormat.format_response(User.all(order: [ :netid.desc ]), request.accept)
            end
            
            app.get '/users/search' do
              graduation_start = params["graduationStart"] # YYYY-MM-DD
              graduation_end = params["graduationEnd"] # YYYY-MM-DD
              
              graduation_start_date = DateTime.parse(graduation_start) if graduation_start
              graduation_end_date = DateTime.parse(graduation_end) if graduation_end
              
              netid = params["netid"]
              level = params["level"] # Undergraduate, Masters, PHD
              seeking = params["seeking"] # Internship (co-op), or Full time
              
              num_per_page = params["page"].to_i if params["num_per_page"] && params["num_per_page"].match(/^\d+$/)
              page = (params["page"] && params["page"].match(/^\d+$/)) ? params["page"].to_i : 1
              
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
                user_json[:resume_url] = AWS.fetch_resume(netid)
                
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
              params = JSON.parse(request.body.read)

              user ||= User.first(netid: params[:netid]) || halt(404)
              ResponseFormat.format_response(user, request.accept)
            end

            app.put '/users/:netid' do
              params = JSON.parse(request.body.read)
              
              first_name = params["firstName"]
              last_name = params["lastName"]
              netid = params["netid"]
              email = params["email"]
              graduation_date = params["gradYear"]
              degree_type = params["degreeType"]
              job_type = params["jobType"]
              
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
              params = JSON.parse(request.body.read)

              user ||= User.first(netid: params[:netid]) || halt(404)
              AWS.delete_resume(user.netid)
              
              halt 500 unless user.destroy
            end
        end
    end
    register UsersRoutes
end
