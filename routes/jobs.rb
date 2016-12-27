# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
module Sinatra
  module JobsRoutes
    def self.registered(app)
      app.get '/jobs' do
        ResponseFormat.format_response(Job.all(order: [ :posted_on.desc ], status: "Defer"), request.accept)
      end
      
      app.post '/jobs' do
        # TODO protected, look for recruiter in session before continuing
        params = ResponseFormat.get_params(request.body.read)
        halt(400) unless Auth.verify_admin(env)

        Job.validate!(params, [:job_title, :organization, :contact_name, :contact_email, :contact_phone, :job_type, :description, :expires_on])
        
        job = (Job.first_or_create({
          title: params[:job_title],
          company: params[:organization]
        }, {
          contact_name: params[:contact_name],
          contact_email: params[:contact_email],
          contact_phone: params[:contact_phone],
          job_type: params[:job_type],
          description: params[:description],
          expires_on: params[:expires_on],
          posted_on: Date.today,
          status: "Defer"
          })
        )
      
        return [200, ResponseFormat.format_response(job, request.accept)]
      end
      
      app.put '/jobs/status' do
        halt(400) unless Auth.verify_admin(env)

        params = ResponseFormat.get_params(request.body.read)
        Job.validate!(params, [:job_title, :organization, :status])
        
        job = Job.first(title: params[:job_title], company: params[:organization]) || halt(400)
        
        job.status = params[:status]
        job.save!
      end
      
      app.delete '/jobs' do
        halt(400) unless Auth.verify_admin(env)

        params = ResponseFormat.get_params(request.body.read)
        Job.validate!(params, [:job_title, :organization])
        
        job = Job.first(title: params[:job_title], company: params[:organization]) || halt(400)
        halt 500 unless job.destroy
      end
    end
  end
  register JobsRoutes
end