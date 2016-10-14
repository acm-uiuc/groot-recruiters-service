# encoding: UTF-8
require 'pry'

module Sinatra
  module RecruiterRoutes
    def self.registered(app)
      app.post '/new_recruiter' do
        string = request.body.read.gsub(/=>/, ':')
        payload = JSON.parse(string)

        return [400, 'Missing company name'] unless payload['company_name']
        return [400, "Missing recruiter's first name"] unless payload['first_name']
        return [400, "Missing recruiter's last name"] unless payload['last_name']
        return [400, "Missing recruiter's email"] unless payload['email']

        # Recruiter with these parameters should not exist already
        recruiter = Recruiter.first(company_name: payload['company_name'], first_name: payload['first_name'], last_name: payload['last_name'])

        return [400, 'Already found recruiter'] if recruiter

        r = Recruiter.create(
          company_name: payload['company_name'],
          first_name: payload['first_name'],
          last_name: payload['last_name'],
          type: payload['type']
        )
        encryption = Config.load_config('encryption')

        random_password = ('a'..'z').to_a.sample(8).join

        r.encrypted_password = Digest::MD5.hexdigest(encryption['secret'] + random_password)
        r.save

        # send email
        'corporate@acm.illinois.edu'

        subject = '[Corporate-l] ACM@UIUC Resume Book'

        credentials = Config.load_config('email')

        Pony.options = {
          subject: '[Corporate-l] ACM@UIUC Resume Book',
          body: "Hi #{payload['company_name']}, an account has been created for you. TESTING \n#{random_password}",
          via: :smtp,
          via_options: {
            address: 'smtp.gmail.com',
            port: '587',
            enable_starttls_auto: true,
            user_name: credentials['email'],
            password: credentials['password'],
            authentication: :plain, # :plain, :login, :cram_md5, no auth by default
            domain: 'localhost.localdomain'
          }
        }

        return [200, 'Created recruiter']
      end
    end
  end
  register RecruiterRoutes
end
