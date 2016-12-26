# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
# encoding: UTF-8
require 'pry'
require 'pony'

module Sinatra
  module RecruitersRoutes
    def self.registered(app)
      app.get '/recruiters/login' do
        params = JSON.parse(request.body.read)

        return [400, "Missing company login"] unless params['email']
        return [400, "Missing password"] unless params['password']
        
        encryption_key = Config.load_config('encryption')
        encrypted_password = Digest::MD5.hexdigest(encryption_key['secret'] + params['password'])
        
        recruiter = Recruiter.first(email: params['email'], encrypted_password: encrypted_password)
        
        return [400, "Invalid credentials"] unless recruiter
        return [400, "Account has expired!"] if recruiter.expires_at < Date.today
        
        session[:recruiter] = recruiter.id

        return [200, "OK"]
      end

      app.post '/recruiters' do
        params = JSON.parse(request.body.read)
        
        return [400, "Missing company name"] unless params['company_name']
        return [400, "Missing recruiter's first name"] unless params['first_name']
        return [400, "Missing recruiter's last name"] unless params['last_name']
        return [400, "Missing recruiter's email"] unless params['email']
        return [400, "Missing type"] unless params['type']
        
        # Recruiter with these parameters should not exist already
        recruiter = Recruiter.first(company_name: params['company_name'], first_name: params['first_name'], last_name: params['last_name'])

        return [400, 'Recruiter already exists'] if recruiter

        r = Recruiter.new
        
        r.company_name = params['company_name']
        r.first_name = params['first_name']
        r.email = params['email']
        r.last_name = params['last_name']
        r.type = params['type']
        
        encryption = Config.load_config('encryption')

        random_password = ('a'..'z').to_a.sample(8).join

        r.encrypted_password = Digest::MD5.hexdigest(encryption['secret'] + random_password)
        
        r.expires_at = Date.today.next_year
        
        subject = '[Corporate-l] ACM@UIUC Resume Book'
        html_body = erb :new_account_email, locals: { recruiter: r, password: random_password }

        credentials = Config.load_config('email')

        Pony.options = {
          subject: subject,
          body: html_body,
          via: :smtp,
          via_options: {
            address: 'smtp.gmail.com',
            port: '587',
            enable_starttls_auto: true,
            user_name: credentials['username'],
            password: credentials['password'],
            authentication: :plain,
            domain: 'localhost.localdomain'
          }
        }
        Pony.mail(to: params["email"])
        # Save if the email sent
        r.save
        
        # Created recruiter and sent registration email
        return [200, 'OK']
      end

      app.get '/recruiters/reset_password' do
        params = JSON.parse(request.body.read)

        return [400, "Missing email"] unless params['email']
        return [400, "Missing first name"] unless params['first_name']
        return [400, "Missing last name"] unless params['last_name']
        recruiter = Recruiter.first(email: params['email'])
        
        return [400, "Recruiter with email and name combination not found"] unless recruiter

        # Generate new password
        encryption = Config.load_config('encryption')
        random_password = ('a'..'z').to_a.sample(8).join # TODO move this to helper
        recruiter.encrypted_password = Digest::MD5.hexdigest(encryption['secret'] + random_password)
        
        subject = '[Corporate-l] ACM@UIUC Resume Book: New Password Request'
        html_body = erb :forgot_password_email, locals: { recruiter: recruiter, password: random_password }

        credentials = Config.load_config('email')
        
        Pony.options = {
          subject: subject,
          body: html_body,
          via: :smtp,
          via_options: {
            address: 'smtp.gmail.com',
            port: '587',
            enable_starttls_auto: true,
            user_name: credentials['username'],
            password: credentials['password'],
            authentication: :plain,
            domain: 'localhost.localdomain'
          }
        }
        Pony.mail(to: params["email"])
        
        recruiter.save
        
        return [200, "Sent recruiter email with new password"]
      end
      
      app.put '/recruiters/' do
        params = JSON.parse(request.body.read)

        return [400, "Missing email"] unless params['email']
        return [400, "Missing password"] unless params['password']
        return [400, "Missing password"] unless params['new_password']
        
        # Check that recruiter's password matches what's in the database
        encryption_key = Config.load_config('encryption')
        encrypted_password = Digest::MD5.hexdigest(encryption_key['secret'] + params['password'])
        
        recruiter = Recruiter.first(email: params['email'], encrypted_password: encrypted_password)
        
        return [400, "Invalid email or password combination"] unless recruiter
        
        new_encrypted_password = Digest::MD5.hexdigest(encryption_key['secret'] + params['new_password'])
        recruiter.encrypted_password = new_encrypted_password
        recruiter.save
        
        return [200, "OK"]
      end

      app.post '/recruiters/logout' do        
        session.clear

        return [200, "OK"]
      end
    end
  end
  register RecruitersRoutes
end
