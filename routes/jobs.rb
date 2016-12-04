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
              string = request.body.read.gsub(/=>/, ":")
              payload = JSON.parse(string)
              
              return [400, "Missing job title"] unless payload["job_title"]
              return [400, "Missing organization"] unless payload["org"]
              return [400, "Missing contact_name"] unless payload["contact-name"]
              return [400, "Missing contact email"] unless payload["contact-email"]
              return [400, "Missing contact phone"] unless payload["contact-phone"]
              return [400, "Missing job type"] unless payload["job-type"]
              return [400, "Missing description"] unless payload["description"]
              
              job = (Job.first_or_create(
                  {
                      title: payload["job_title"],
                      company: payload["org"]
                  }, {
                      contact_name: payload["contact-name"],
                      contact_email: payload["contact-email"],
                      contact_phone: payload["contact-phone"],
                      job_type: payload["job-type"],
                      description: payload["description"],
                      posted_on: Time.now.getutc,
                      status: "Defer"
                  }
              ))
            
              return [200, ResponseFormat.format_response(job, request.accept)]
            end
            
            app.put '/jobs/status' do
              string = request.body.read.gsub(/=>/, ":")
              payload = JSON.parse(string)
              
              return [400, "Missing job title"] unless payload["job_title"]
              return [400, "Missing organization"] unless payload["org"]
              return [400, "Missing job status"] unless payload["status"]
              
              if Job.is_valid_status(payload["status"])
                job ||= Job.first(title: payload["job_title"], company: payload["org"]) || halt(404)
                
                job.status = payload["status"]
                job.save!
              else
                return [400, "Invalid status #{payload['status']}"]
              end
            end
            
            app.delete '/jobs' do
              string = request.body.read.gsub(/=>/, ":")
              payload = JSON.parse(string)
              
              return [400, "Missing job title"] unless payload["job_title"]
              return [400, "Missing organization"] unless payload["org"]
              
              job ||= Job.first(title: payload["job_title"], company: payload["org"]) || halt(404)
              halt 500 unless job.destroy
            end
        end
    end
    register JobsRoutes
end