module Sinatra
    module JobsRoutes
        def self.registered(app)
            app.get '/jobs' do
                ResponseFormat.format_response(Job.all(order: [ :posted_on.desc ]), request.accept)
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
                      posted_on: Time.now.getutc
                  }
              ))
            
              return [200, ResponseFormat.format_response(job, request.accept)]
            end
            
            # TODO a.put/jobs/status
            
            
        end
    end
    register JobsRoutes
end