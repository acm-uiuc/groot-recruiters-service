# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
# encoding: UTF-8
require 'pry'

module Sinatra
  module RecruitersRoutes
    def self.registered(app)
      app.post '/recruiters/login' do
        params = ResponseFormat.get_params(request.body.read)
      
        status, error = Recruiter.validate(params, [:email, :password])
        halt status, ResponseFormat.error(error) if error

        recruiter = Recruiter.first(email: params[:email])

        halt 400, ResponseFormat.error("Invalid credentials") unless recruiter

        correct_credentials = Encrypt.valid_password?(recruiter.encrypted_password, params[:password])
        halt 400, ResponseFormat.error("Invalid credentials") unless correct_credentials
        halt 400, ResponseFormat.error("Account has expired!") if recruiter.expires_on < Date.today
        
        ResponseFormat.success(recruiter)
      end

      app.post '/recruiters' do
        params = ResponseFormat.get_params(request.body.read)
        status, error = Recruiter.validate(params, [:company_name, :first_name, :last_name, :email])
        halt status, ResponseFormat.error(error) if error

        # Recruiter with these parameters should not exist already
        recruiter = Recruiter.first(company_name: params[:company_name], first_name: params[:first_name], last_name: params[:last_name])

        halt 400, ResponseFormat.error("Recruiter already exists") if error

        r = Recruiter.new
        r.company_name = params[:company_name]
        r.first_name = params[:first_name]
        r.last_name = params[:last_name]
        r.email = params[:email]
        random_password, encrypted = Encrypt.generate_encrypted_password
        r.encrypted_password = encrypted
        r.expires_on = Date.today.next_year
        
        subject = '[Corporate-l] ACM@UIUC Resume Book'
        html_body = erb :new_account_email, locals: { recruiter: r, password: random_password }

        if Mailer.email(subject, html_body, params[:email])
          r.save
          ResponseFormat.message("Sent recruiter email with new password")
        else
          halt 400, ResponseFormat.error("Error sending recruiter email. Failed to save recruiter in db")
        end
      end

      app.post '/recruiters/:recruiter_id/reset_password' do
        status, error = Recruiter.validate(params, [:recruiter_id])
        halt status, ResponseFormat.error(error) if error

        recruiter = Recruiter.get(params[:recruiter_id])
        halt 404, ResponseFormat.error("Recruiter doesn't exist") unless recruiter

        # Generate new password
        random_password, encrypted = Encrypt.generate_encrypted_password
        recruiter.encrypted_password = encrypted
        
        subject = '[Corporate-l] ACM@UIUC Resume Book: New Password Request'
        html_body = erb :forgot_password_email, locals: { recruiter: recruiter, password: random_password }

        if Mailer.email(subject, html_body, params[:email])
          recruiter.save
          ResponseFormat.message("Sent recruiter email with new password")
        else
          halt 400, ResponseFormat.error("Error sending recruiter email. Failed to save recruiter in db")
        end
      end
      
      app.put '/recruiters/:recruiter_id' do
        params = ResponseFormat.get_params(request.body.read)
        status, error = Recruiter.validate(params, [:recruiter_id, :email, :password, :new_password])
        halt status, ResponseFormat.error(error) if error

        recruiter = Recruiter.first(email: params[:email])
        halt 400, ResponseFormat.error("Invalid credentials") unless recruiter        

        correct_credentials = Encrypt.valid_password?(recruiter.encrypted_password, params[:password])
        halt 400, ResponseFormat.error("Invalid credentials") unless correct_credentials

        recruiter.encrypted_password = Encrypt.encrypt_password(params[:new_password])
        recruiter.save
        
        ResponseFormat.message("Recruiter updated successfully")
      end
    end
  end
  register RecruitersRoutes
end
