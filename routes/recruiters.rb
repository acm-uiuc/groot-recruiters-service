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
  module RecruiterRoutes
    def self.registered(app)
      app.get '/recruiters/login' do
        string = request.body.read.gsub(/=>/, ':')
        payload = JSON.parse(string)
        
        return [400, "Missing company login"] unless payload['email']
        return [400, "Missing password"] unless payload['password']
        
        encryption_key = Config.load_config('encryption')
        encrypted_password = Digest::MD5.hexdigest(encryption_key['secret'] + payload['password'])
        
        recruiter = Recruiter.first(email: payload['email'], encrypted_password: encrypted_password)
        
        return [400, "Invalid credentials"] unless recruiter
        return [400, "Account has expired!"] if recruiter.expires_at < Date.today
        
        return [200, "OK"]
      end
      
      app.get '/recruiters/reset_password' do
        string = request.body.read.gsub(/=>/, ':')
        payload = JSON.parse(string)
        
        return [400, "Missing email"] unless payload['email']
        return [400, "Missing first name"] unless payload['first_name']
        return [400, "Missing last name"] unless payload['last_name']
        recruiter = Recruiter.first(email: payload['email'])
        
        return [400, "Recruiter with email and name combination not found"] unless recruiter
        
        # Generate new password
        encryption = Config.load_config('encryption')
        random_password = ('a'..'z').to_a.sample(8).join
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
        Pony.mail(to: payload["email"])
        
        recruiter.save
        
        return [200, "Sent recruiter email with new password"]
      end
      
      app.put '/recruiters/' do
        string = request.body.read.gsub(/=>/, ':')
        payload = JSON.parse(string)
        
        return [400, "Missing email"] unless payload['email']
        return [400, "Missing password"] unless payload['password']
        return [400, "Missing password"] unless payload['new_password']
        
        # Check that recruiter's password matches what's in the database
        encryption_key = Config.load_config('encryption')
        encrypted_password = Digest::MD5.hexdigest(encryption_key['secret'] + payload['password'])
        
        recruiter = Recruiter.first(email: payload['email'], encrypted_password: encrypted_password)
        
        return [400, "Invalid email or password combination"] unless recruiter
        
        new_encrypted_password = Digest::MD5.hexdigest(encryption_key['secret'] + payload['new_password'])
        recruiter.encrypted_password = new_encrypted_password
        recruiter.save
        
        return [200, "OK"]
      end
      
      app.post '/recruiters/new' do
        string = request.body.read.gsub(/=>/, ':')
        payload = JSON.parse(string)

        return [400, "Missing company name"] unless payload['company_name']
        return [400, "Missing recruiter's first name"] unless payload['first_name']
        return [400, "Missing recruiter's last name"] unless payload['last_name']
        return [400, "Missing recruiter's email"] unless payload['email']
        return [400, "Missing type"] unless payload['type']
        
        # Recruiter with these parameters should not exist already
        recruiter = Recruiter.first(company_name: payload['company_name'], first_name: payload['first_name'], last_name: payload['last_name'])

        return [400, 'Recruiter already exists'] if recruiter

        r = Recruiter.new
        
        r.company_name = payload['company_name']
        r.first_name = payload['first_name']
        r.email = payload['email']
        r.last_name = payload['last_name']
        r.type = payload['type']
        
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
        Pony.mail(to: payload["email"])
        # Save if the email sent
        r.save
        
        return [200, 'Created recruiter and sent registration email']
      end
    end
  end
  register RecruiterRoutes
end
