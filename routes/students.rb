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
    module StudentsRoutes
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
            
            app.get '/students' do
              # TODO ask about authentication
              param :graduationStart,   String # YYYY-MM-DD
              param :graduationEnd,     String
              param :netid,             String
              param :degree_type,       String, in: ["Undergraduate", "Masters", "PhD", ""], default: ""
              param :job_type,          String, in: ["Internship", "Full-time", "Co-Op", ""], default: ""
              # param :approved_resumes   Boolean

              graduation_start_date = Date.parse(params[:graduationStart]) rescue nil
              graduation_end_date = Date.parse(params[:graduationEnd]) rescue nil
              
              conditions = {}.tap do |conditions|
                conditions[:netid] = params[:netid] if params[:netid] && !params[:netid].empty?
                conditions[:"graduation_date.gt"] = graduation_start_date if graduation_start_date
                conditions[:"graduation_date.lt"] = graduation_end_date if graduation_end_date
                conditions[:degree_type] = params[:degree_type] if params[:degree_type] && !params[:degree_type].empty?
                conditions[:job_type] = params[:job_type] if params[:job_type] && !params[:job_type].empty?
                conditions[:active] = true
                conditions[:approved_resume] = params[:approved_resumes] if params[:approved_resumes] && !params[:approved_resumes].nil?
              end
              
              matching_students = Student.all(conditions) # TODO store resume url
              
              ResponseFormat.format_response(matching_students, request.accept)
            end

            app.post '/students' do
                json_params = JSON.parse(request.body.read)
                params = {}
                json_params.each { |k, v| params[k.to_sym] = v }

                # param :firstName,         String, required: true
                # param :lastName,          String, required: true
                # param :netid,             String, required: true
                # param :email,             String, required: true
                # param :gradYear,          String, required: true # YYYY-MM-DD
                # param :degreeType,        String, required: true
                # param :jobType,           String, required: true
                # param :resume,            String, required: true
                
                status = 403
                if Student.is_valid?(params[:firstName], params[:lastName], params[:netid])
                  status = 200
                  student = (
                    Student.first_or_create({
                      netid: params[:netid]
                    }, {
                      first_name: params[:firstName].capitalize,
                      last_name: params[:lastName].capitalize,
                      netid: params[:netid],
                      email: params[:email],
                      graduation_date: params[:gradYear],
                      program: params[:degreeType],
                      job_type: params[:jobType],
                      date_joined: Time.now.getutc,
                      active: true
                    })
                  )
                    
                  successful_upload = AWS.upload_resume(params[:netid], params[:resume])
                  return [400, "Error uploading resume to S3"] unless successful_upload
                  # TODO check if student.resume = successful_upload

                  student.approved_resume = false
                  student.save!
                end
                return [status, ResponseFormat.format_response(student, request.accept)]
            end

            app.put '/students/:netid/approve' do
              # TODO authentication
              # if you don't wanna approve, you delete
              
              student = Student.first(netid: params[:netid])
              return [400, "Student not found"] unless student
              return [400, "Resume already approved"] if student.approved_resume
              student.update(approved_resume: true) || halt(500)
            end

            app.get '/students/:netid' do
              # params = JSON.parse(request.body.read)
              # TODO needs to be protected

              student = Student.first(netid: params[:netid]) || halt(404)
              ResponseFormat.format_response(student, request.accept)
            end

            # app.put '/students/:netid' do
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
              
            #   student = Student.first(netid: netid) || halt(404)
            #   halt 500 unless student.update(
            #       first_name: params[:firstName],
            #       last_name: params[:lastName],
            #       netid: params[:netid],
            #       email: params[:email],
            #       graduation_date: graduation_date_obj,
            #       degree_type: params[:degreeType],
            #       job_type: params[:jobType]
            #   )
            #   return [200, ResponseFormat.format_response(student, request.accept)]
            # end

            app.delete '/students/:netid' do
              # authentication

              # params = JSON.parse(request.body.read)

              student ||= Student.first(netid: params[:netid]) || halt(404)
              AWS.delete_resume(student.netid)
              email = student.email # TODO send email to student before deleting
              halt 500 unless student.destroy
            end
        end
    end
    register StudentsRoutes
end
