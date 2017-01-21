# Copyright © 2017, ACM@UIUC
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
require 'open-uri'

module Sinatra
  module StudentsRoutes
    def self.registered(app)
      app.get '/students' do
        payload = JWTAuth.decode(env)
        halt 401, Errors::VERIFY_CORPORATE_SESSION unless Auth.verify_corporate_session(env) || (payload[:code] == 200)

        graduation_start_date = Date.parse(params[:graduationStart]) rescue nil
        graduation_end_date = Date.parse(params[:graduationEnd]) rescue nil
        
        last_updated_at = Date.parse(params[:last_updated_at]) rescue nil
        return 400, ERRORS::FUTURE_DATE if last_updated_at && last_updated_at > Date.today

        conditions = {}.tap do |conditions|
          conditions[:first_name] = params[:name].split.first if params[:name] && !params[:name].empty?
          conditions[:netid] = params[:netid] if params[:netid] && !params[:netid].empty?
          conditions[:"graduation_date.gte"] = graduation_start_date if graduation_start_date
          conditions[:"graduation_date.lte"] = graduation_end_date if graduation_end_date
          conditions[:"updated_at.lte"] = last_updated_at if last_updated_at
          conditions[:degree_type] = params[:degree_type] if params[:degree_type] && !params[:degree_type].empty?
          conditions[:job_type] = params[:job_type] if params[:job_type] && !params[:job_type].empty?
          conditions[:active] = true
          conditions[:approved_resume] = (!params[:approved_resumes].nil?) ? params[:approved_resumes] : true # show approved resumes by default, but this is second to whatever was sent
        end
        
        conditions[:order] = [ :last_name.asc, :first_name.asc ]
        matching_students = Student.all(conditions)

        ResponseFormat.data(matching_students)
      end

      app.post '/students' do
        params = ResponseFormat.get_params(request.body.read)

        status, error = Student.validate(params, [:netid, :firstName, :lastName, :email, :gradYear, :degreeType, :jobType, :resume])

        halt status, ResponseFormat.error(error) if error

        student = (
          Student.first_or_create({
            netid: params[:netid]
          }, {
            first_name: params[:firstName].capitalize,
            last_name: params[:lastName].capitalize,
            netid: params[:netid],
            email: params[:email],
            graduation_date: params[:gradYear],
            degree_type: params[:degreeType],
            job_type: params[:jobType],
            date_joined: Date.today,
            active: true
          })
        )
        # TODO check if previous resume was there and delete? Do we only want one copy of each resume on S3?

        file_name = "#{params[:netid]}-#{SecureRandom.uuid}"
        successful_upload = AWS.upload_resume(file_name, params[:resume])
        halt 400, ResponseFormat.error("There was an error uploading your resume to S3") unless successful_upload
        
        student.resume_url = AWS.fetch_resume(file_name)
        student.approved_resume = false
        student.save!
        
        ResponseFormat.message("Uploaded your information successfully!")
      end

      app.put '/students/:netid/approve' do
        halt 401, Errors::VERIFY_CORPORATE_SESSION unless Auth.verify_corporate_session(env)

        status, error = Student.validate(params, [:netid])
        halt status, ResponseFormat.error(error) if error

        student = Student.first(netid: params[:netid])
        halt 400, ResponseFormat.error("Student not found") unless student
        halt 400, ResponseFormat.error("Resume already approved") if student.approved_resume
        
        student.update(approved_resume: true) || halt(500, ResponseFormat.error("Error updating student."))

        ResponseFormat.data(Student.all(order: [ :date_joined.desc ], approved_resume: false))
      end

      app.get '/students/:netid' do
        student = Student.first(netid: params[:netid]) || halt(404, Errors::STUDENT_NOT_FOUND)
        ResponseFormat.data(student)
      end

      app.delete '/students/:netid' do
        halt 401, Errors::VERIFY_CORPORATE_SESSION unless Auth.verify_corporate_session(env)

        student = Student.first(netid: params[:netid]) || halt(404, Errors::STUDENT_NOT_FOUND)
        AWS.delete_resume(student.netid, student.resume_url)
        student.destroy!

        ResponseFormat.data(Student.all(order: [ :date_joined.desc ], approved_resume: false))
      end

      app.post '/students/remind' do
        halt 401, Errors::VERIFY_CORPORATE_SESSION unless Auth.verify_corporate_session(env)
        params = ResponseFormat.get_params(request.body.read)

        status, error = Student.validate(params, [:email, :last_updated_at])
        halt status, ResponseFormat.error(error) if error

        last_updated_at = Date.parse(params[:last_updated_at]) rescue nil
        return 400, ERRORS::INVALID_DATE unless last_updated_at
        return 400, ERRORS::FUTURE_DATE if last_updated_at > Date.today

        reminded_students = Student.all({:"updated_at.lte" => last_updated_at})

        reminded_students.each do |student|
          subject = '[Corporate-l] ACM@UIUC Resume Update Reminder'
          html_body = erb :update_resume_email, locals: { student: student }
          
          attachment = {
            file_name: "#{student.netid}.pdf",
            file_content: open(student.resume_url).read
          }
          Mailer.email(subject, html_body, params[:email], student.email, attachment)
        end

        ResponseFormat.message("Emailed #{reminded_students.count} students.")
      end
    end
  end
  register StudentsRoutes
end
