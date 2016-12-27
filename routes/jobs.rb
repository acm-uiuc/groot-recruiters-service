# Copyright © 2016, ACM@UIUC
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
        ResponseFormat.format_response(Job.all(order: [ :posted_on.desc ], approved: false), request.accept)
      end
      
      app.post '/jobs' do
        params = ResponseFormat.get_params(request.body.read)

        status, error = Job.validate!(params, [:job_title, :organization, :contact_name, :contact_email, :contact_phone, :job_type, :description])
        return [status, error] if error
        
        job = (
          Job.first_or_create({
            title: params[:job_title].capitalize,
            company: params[:organization].capitalize
          }, {
            contact_name: params[:contact_name].capitalize,
            contact_email: params[:contact_email],
            contact_phone: params[:contact_phone],
            job_type: params[:job_type],
            description: params[:description],
            posted_on: Date.today,
            approved: false
          })
        )
      
        return [200, ResponseFormat.format_response(job, request.accept)]
      end
      
      app.put '/jobs/:job_id/approve' do
        halt(400) unless Auth.verify_admin(env)

        status, error = Job.validate!(params, [:job_id])
        return [status, error] if error
        
        job = Job.get(params[:job_id]) || halt(404)
        return [400, "Job already approved"] if job.approved
        
        job.approved = true
        job.save!
        
        return [200, ResponseFormat.format_response(job, request.accept)]
      end
      
      app.delete '/jobs/:job_id' do
        halt(400) unless Auth.verify_admin(env)

        status, error = Job.validate!(params, [:job_id])
        return [status, error] if error
        
        job = Job.get(params[:job_id]) || halt(400)
        job.destroy!
        
        [200, "Job removed"]
      end
    end
  end
  register JobsRoutes
end