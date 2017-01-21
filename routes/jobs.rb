# Copyright © 2017, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
require 'pry'

module Sinatra
  module JobsRoutes
    def self.registered(app)
      app.get '/jobs' do
        ResponseFormat.data(Job.all(order: [ :created_on.desc ], approved: params[:approved] || false))
      end
      
      app.post '/jobs' do
        params = ResponseFormat.get_params(request.body.read)

        status, error = Job.validate(params, [:job_title, :organization, :contact_name, :contact_email, :contact_phone, :job_type, :description])
        halt status, ResponseFormat.error(error) if error
        
        job = (
          Job.first_or_create({
            title: params[:job_title],
            company: params[:organization]
          }, {
            contact_name: params[:contact_name],
            contact_email: params[:contact_email],
            contact_phone: params[:contact_phone],
            job_type: params[:job_type],
            description: params[:description],
            approved: false
          })
        )
      
        ResponseFormat.message("Job uploaded successfully!")
      end
      
      app.put '/jobs/:job_id/approve' do
        halt(400, Errors::VERIFY_CORPORATE_SESSION) unless Auth.verify_corporate_session(env)

        status, error = Job.validate(params, [:job_id])
        halt(status, ResponseFormat.error(error)) if error
        
        job = Job.get(params[:job_id]) || halt(404, Errors::JOB_NOT_FOUND)
        halt(400, Errors::JOB_APPROVED) if job.approved
        job.update(approved: true)
        
        ResponseFormat.data(Job.all(order: [ :created_on.desc ], approved: false))
      end
      
      app.delete '/jobs/:job_id' do
        halt(400, Errors::VERIFY_CORPORATE_SESSION) unless Auth.verify_corporate_session(env)

        status, error = Job.validate(params, [:job_id])
        halt(status, ResponseFormat.error(error)) if error
        
        job = Job.get(params[:job_id]) || halt(404, Errors::JOB_NOT_FOUND)
        job.destroy!
        
        ResponseFormat.data(Job.all(order: [ :created_on.desc ], approved: false))
      end
    end
  end
  register JobsRoutes
end