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
require 'sinatra/param'

module Sinatra
    module UsersRoutes
        def self.registered(app)
            app.get '/status' do
              return [200, "OK"]
            end
            
            # HANDLE CORS
            app.options "*" do
              response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
              response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept, Origin, Access-Control-Allow-Origin"
              response.headers["Access-Control-Allow-Origin"] = "*"
              200
            end
            
            app.get '/users' do
              # TODO ask about authentication
              param :graduationStart,   String # YYYY-MM-DD
              param :graduationEnd,     String
              param :netid,             String
              param :degree_type,       String, in: ["Undergraduate", "Masters", "PhD", ""], default: ""
              param :job_type,          String, in: ["Internship", "Full-time", "Co-Op", ""], default: ""
              param :approved_resumes   Boolean
              # param :num_per_page,      Integer, default: 50
              # param :page,              Integer, default: 1, min: 1

              # page = params[:page]
              # num_per_page = params[:num_per_page]

              graduation_start_date = Date.parse(params[:graduationStart]) rescue nil
              graduation_end_date = Date.parse(params[:graduationEnd]) rescue nil
              
              conditions = {}.tap do |conditions|
                conditions[:netid] = params[:netid] unless params[:netid].empty?
                conditions[:"graduation_date.gt"] = graduation_start_date if graduation_start_date
                conditions[:"graduation_date.lt"] = graduation_end_date if graduation_end_date
                conditions[:degree_type] = params[:degree_type] unless params[:degree_type].empty?
                conditions[:job_type] = params[:job_type] unless params[:job_type].empty?
                conditions[:active] = true
                conditions[:approved_resume] = params[:approved_resumes] unless params[:approved_resumes].nil?
              end
              
              matching_users = User.all(conditions) # TODO store resume url on user model
              
              # start = (page - 1) * num_per_page
              
              # response = {}.tap do |response|
              #   response[:results] = []
              #   # response[:next_page] = page + 1 if start + num_per_page < matching_users.count
              #   # response[:previous_page] = page - 1 if page > 1
              # end
              
              # matching_users[start..start + num_per_page].each do |user|
              #   netid = user["netid"]
              #   user_json = JSON.parse(user.to_json)
              #   user_json[:resume_url] = AWS.fetch_resume(netid) 
                
              #   # TODO implement this
              #   # groot_url = "http://localhost:8000"
              #   # is_member_url = "/users/#{netid}/isMember"
                
              #   response[:results] << user_json
              # end
              
              ResponseFormat.format_response(matching_users, request.accept)
            end

            app.post '/users' do
                params = JSON.parse(request.body.read)

                param :firstName,         String, required: true
                param :lastName,          String, required: true
                param :netid,             String, required: true
                param :email,             String, required: true
                param :gradYear,          String, required: true # YYYY-MM-DD
                param :degreeType,        String, required: true
                param :jobType,           String, required: true
                param :resume,            String, required: true


                # first_name = params["firstName"]
                # last_name = params["lastName"]
                # netid = params["netid"]
                # email = params["email"]
                # graduation_date = params["gradYear"]
                # degree_type = params["degreeType"]
                # job_type = params["jobType"]
                # resume = params["resume"]
                
                # return [400, "Missing first_name"] unless first_name
                # return [400, "Missing netid"] unless netid
                # return [400, "Missing email"] unless email
                # return [400, "Missing grad_year"] unless graduation_date
                # return [400, "Missing degree_type"] unless degree_type
                # return [400, "Missing job_type"] unless job_type
                
                status = 403
                if User.is_valid_user?(params[:firstName], params[:lastName], params[:netid])
                  status = 200
                  user = (
                    User.first_or_create({
                      netid: netid
                    }, {
                      first_name: first_name.capitalize,
                      last_name: last_name.capitalize,
                      netid: netid,
                      email: email,
                      graduation_date: graduation_date,
                      degree_type: degree_type,
                      job_type: job_type,
                      date_joined: Time.now.getutc,
                      active: true
                    })
                  )
                    
                  successful_upload = AWS.upload_resume(params[:netid], params[:resume])
                  return [400, "Error uploading resume to S3"] unless successful_upload
                  # TODO check if user.resume = successful_upload

                  user.approved_resume = false
                  user.save!
                end
                return [status, ResponseFormat.format_response(user, request.accept)]
            end

            app.put '/users/:netid/approve' do
              # TODO authentication
              # if you don't wanna approve, you delete
              
              user = User.first(netid: params[:netid])
              return [400, "User not found"] unless user
              return [400, "Resume already approved"] if user.approved_resume
              user.update(approved_resume: true) || halt(500)
            end

            # app.get '/users/:netid' do
            #   # params = JSON.parse(request.body.read)
            #   # TODO needs to be protected

            #   user = User.first(netid: params[:netid]) || halt(404)
            #   ResponseFormat.format_response(user, request.accept)
            # end

            # app.put '/users/:netid' do
            #   # params = JSON.parse(request.body.read)
            #   # TODO authentication

            #   param :firstName,         String, required: true
            #   param :lastName,          String, required: true
            #   param :netid,             String, required: true
            #   param :email,             String, required: true
            #   param :gradYear,          String, required: true # YYYY-MM-DD
            #   param :degreeType,        String, required: true
            #   param :jobType,           String, required: true
              
            #   # first_name = params["firstName"]
            #   # last_name = params["lastName"]
            #   # netid = params["netid"]
            #   # email = params["email"]
            #   # graduation_date = params["gradYear"]
            #   # degree_type = params["degreeType"]
            #   # job_type = params["jobType"]
              
            #   # return [400, "Missing first_name"] unless first_name
            #   # return [400, "Missing netid"] unless netid
            #   # return [400, "Missing email"] unless email
            #   # return [400, "Missing grad_year"] unless graduation_date
            #   # return [400, "Missing degree_type"] unless degree_type
            #   # return [400, "Missing job_type"] unless job_type
              
            #   graduation_date_obj = DateTime.parse(gradYear)
              
            #   user = User.first(netid: netid) || halt(404)
            #   halt 500 unless user.update(
            #       first_name: params[:firstName],
            #       last_name: params[:lastName],
            #       netid: params[:netid],
            #       email: params[:email],
            #       graduation_date: graduation_date_obj,
            #       degree_type: params[:degreeType],
            #       job_type: params[:jobType]
            #   )
            #   return [200, ResponseFormat.format_response(user, request.accept)]
            # end

            app.delete '/users/:netid' do
              # authentication

              # params = JSON.parse(request.body.read)

              user ||= User.first(netid: params[:netid]) || halt(404)
              AWS.delete_resume(user.netid)
              email = user.email # TODO send email to user before deleting
              halt 500 unless user.destroy
            end
        end
    end
    register UsersRoutes
end
