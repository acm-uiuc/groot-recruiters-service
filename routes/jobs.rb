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

        return [400, "Missing job title"] unless params[:job_title]
        return [400, "Missing organization"] unless params[:organization]
        return [400, "Missing contact name"] unless params[:contact_name]
        return [400, "Missing contact email"] unless params[:contact_email]
        return [400, "Missing contact phone"] unless params[:contact_phone]
        return [400, "Missing job type"] unless params[:job_type]
        return [400, "Missing description"] unless params[:description]
        
        job = (Job.first_or_create({
          title: params[:job_title],
          company: params[:organization]
        }, {
          contact_name: params[:contact_name],
          contact_email: params[:contact_email],
          contact_phone: params[:contact_phone],
          job_type: params[:job_type],
          description: params[:description],
          posted_on: Time.now.getutc,
          status: "Defer"
          })
        )
      
        return [200, ResponseFormat.format_response(job, request.accept)]
      end
      
      app.put '/jobs/status' do
        params = ResponseFormat.get_params(request.body.read)
        
      #   param :job_title, String, required: true
      #   param :org, String, required: true
      #   param :status, String, in: ["Approve", "Defer"]

        return [400, "Missing job title"] unless params["job_title"]
        return [400, "Missing organization"] unless params["org"]
        return [400, "Missing job status"] unless params["status"]
        
        job ||= Job.first(title: params[:job_title], company: params[:org]) || halt(404)
        
        job.status = params[:status]
        job.save!
      end
      
      app.delete '/jobs' do
        params = ResponseFormat.get_params(request.body.read)

        return [400, "Missing job title"] unless params[:job_title]
        return [400, "Missing organization"] unless params[:organization]
        
        job ||= Job.first(title: params[:job_title], company: params[:organization]) || halt(404)
        halt 500 unless job.destroy
      end
    end
  end
  register JobsRoutes
end