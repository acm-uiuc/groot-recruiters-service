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
  module StudentsRoutes
    def self.registered(app)
      app.get '/students' do
        params = ResponseFormat.get_params(request.body.read)

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

        matching_students = Student.all(conditions)
        
        ResponseFormat.success(matching_students)
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
        
        successful_upload = AWS.upload_resume(params[:netid], params[:resume])
        halt 400, ResponseFormat.error("Error uploading resume to S3") unless successful_upload
        
        student.resume_url = AWS.fetch_resume(params[:netid])
        student.approved_resume = false
        student.save!
        
        ResponseFormat.success(student)
      end

      app.put '/students/:netid/approve' do
        halt(400) unless Auth.verify_admin(env)

        status, error = Student.validate(params, [:netid])
        halt status, ResponseFormat.error(error) if error

        student = Student.first(netid: params[:netid])
        halt 400, ResponseFormat.error("Student not found") unless student
        halt 400, ResponseFormat.error("Resume already approved") if student.approved_resume
        student.update(approved_resume: true) || halt(500, ResponseFormat.error("Error updating student."))

        ResponseFormat.success(student)
      end

      app.get '/students/:netid' do
        student = Student.first(netid: params[:netid]) || halt(404)
        ResponseFormat.success(student)
      end

      app.delete '/students/:netid' do
        halt(400) unless Auth.verify_admin(env)

        student = Student.first(netid: params[:netid]) || halt(404)
        
        AWS.delete_resume(student.netid)
        email = student.email # TODO send email to student before deleting
        
        student.destroy!

        ResponseFormat.message("Student destroyed!")
      end
    end
  end
  register StudentsRoutes
end
