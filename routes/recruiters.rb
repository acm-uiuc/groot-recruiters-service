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
      app.get '/recruiters' do
        halt 400, Errors::VERIFY_CORPORATE_SESSION unless Auth.verify_corporate_session(env)

        conditions = {}.tap do |conditions|
          conditions[:type] = params[:type] if params[:type] && Recruiter.validate(params, [:type])
        end

        conditions[:order] = [ :company_name.asc ]
        matching_recruiters = Recruiter.all(conditions)
        ResponseFormat.data(matching_recruiters)
      end

      app.post '/recruiters/login' do
        params = ResponseFormat.get_params(request.body.read)

        status, error = Recruiter.validate(params, [:email, :password])

        halt status, ResponseFormat.error(error) if error

        recruiter = Recruiter.first(email: params[:email])
        halt 400, Errors::INVALID_CREDENTIALS unless recruiter

        correct_credentials = Encrypt.valid_password?(recruiter.encrypted_password, params[:password])
        halt 400, Errors::INVALID_CREDENTIALS unless correct_credentials
        halt 400, Errors::ACCOUNT_EXPIRED if recruiter.expires_on < Date.today
        
        ResponseFormat.data(recruiter)
      end

      app.post '/recruiters' do
        halt 400, Errors::VERIFY_CORPORATE_SESSION unless Auth.verify_corporate_session(env)

        params = ResponseFormat.get_params(request.body.read)

        status, error = Recruiter.validate(params, [:company_name, :first_name, :last_name, :email, :type])
        halt status, ResponseFormat.error(error) if error

        # Recruiter with these parameters should not exist already
        existing_recruiter = Recruiter.first(company_name: params[:company_name], first_name: params[:first_name], last_name: params[:last_name])
        halt 400, Errors::DUPLICATE_ACCOUNT if existing_recruiter

        r = Recruiter.new
        r.company_name = params[:company_name]
        r.first_name = params[:first_name]
        r.last_name = params[:last_name]
        r.email = params[:email]
        r.type = params[:type]
        random_password, encrypted = Encrypt.generate_encrypted_password
        r.encrypted_password = encrypted if r.is_sponsor? # Other recruiters do not have an account to access the resume book
        r.expires_on = Date.today.next_year
        
        subject = '[Corporate-l] ACM@UIUC Resume Book'
        html_body = erb :new_account_email, locals: { recruiter: r, password: random_password }

        # Only email general recruiters, but save all recruiters
        if !r.is_sponsor? || Mailer.email(subject, html_body, params[:email])
          r.save
          ResponseFormat.message("Created account for #{recruiter.company_name} in our database")
        else
          halt 400, ResponseFormat.error("Failed to create an account for #{recruiter.company_name} in our database")
        end
      end

      app.get '/recruiters/:recruiter_id' do
        halt 400, Errors::VERIFY_CORPORATE_SESSION unless Auth.verify_corporate_session(env)
        
        recruiter = Recruiter.first(params[:recruiter_id]) || halt(404)
        ResponseFormat.data(recruiter)
      end
      
      app.put '/recruiters/:recruiter_id' do
        halt 400, Errors::VERIFY_CORPORATE_SESSION unless Auth.verify_corporate_session(env)

        recruiter_id = params[:recruiter_id]
        params = ResponseFormat.get_params(request.body.read)
        params[:recruiter_id] = recruiter_id

        status, error = Recruiter.validate(params, [:recruiter_id, :email, :password, :new_password, :type])
        halt status, ResponseFormat.error(error) if error
        
        recruiter = Recruiter.get(params[:recruiter_id])
        halt(400, Errors::INVALID_CREDENTIALS) unless recruiter && recruiter.email == params[:email] 
        
        correct_credentials = Encrypt.valid_password?(recruiter.encrypted_password, params[:password])
        halt(400, Errors::INVALID_CREDENTIALS) unless correct_credentials

        # TODO depends on UI, but this could be a portal to update email and/or password. Currently this doesn't account for email.'
        recruiter.encrypted_password = Encrypt.encrypt_password(params[:new_password])
        recruiter.save
        
        ResponseFormat.message("Recruiter updated successfully")
      end

      app.post '/recruiters/reset_password' do
        params = ResponseFormat.get_params(request.body.read)

        status, error = Recruiter.validate(params, [:first_name, :last_name, :email])
        halt status, ResponseFormat.error(error) if error

        recruiter = Recruiter.first(first_name: params[:first_name], last_name: params[:last_name], email: params[:email])
        halt 404, Errors::INCORRECT_RESET_CREDENTIALS unless recruiter

        halt 400, ResponseFormat.error("You cannot reset your password. Your recruiter account type is: #{recruiter.type}") unless recruiter.is_sponsor?

        # Generate new password
        random_password, encrypted = Encrypt.generate_encrypted_password
        recruiter.encrypted_password = encrypted
        
        subject = '[Corporate-l] ACM@UIUC Resume Book: New Password Request'
        html_body = erb :forgot_password_email, locals: { recruiter: recruiter, password: random_password }

        if Mailer.email(subject, html_body, params[:email])
          recruiter.save
          ResponseFormat.message("We have verified your account details. Check your email for a new password.")
        else
          halt 400, ERRORS::EMAIL_ERROR
        end
      end
      
      app.get '/recruiters/:recruiter_id/invite' do
        # halt 400, Errors::VERIFY_CORPORATE_SESSION unless Auth.verify_corporate_session(env)

        recruiter = Recruiter.get(params[:recruiter_id])
        halt 404, Errors::RECRUITER_NOT_FOUND unless recruiter

        invitation = Invitation.new(recruiter)
        ResponseFormat.data(invitation)
      end

      app.post '/recruiters/:recruiter_id/invite' do
        halt 400, Errors::VERIFY_CORPORATE_SESSION unless Auth.verify_corporate_session(env)

      end

      app.post '/recruiters/reset' do
        halt 400, Errors::VERIFY_CORPORATE_SESSION unless Auth.verify_corporate_session(env)

        # reset all recruiters' invited to false
      end

      app.put '/recruiters/:recruiter_id/renew' do
        halt 400, Errors::VERIFY_CORPORATE_SESSION unless Auth.verify_corporate_session(env)

        recruiter = Recruiter.get(params[:recruiter_id])
        halt 404, Errors::RECRUITER_NOT_FOUND unless recruiter

        recruiter.update(expires_on: recruiter.expires_on.next_year)

        ResponseFormat.data(Recruiter.all(order: [ :company_name.asc ]))
      end

      app.delete '/recruiters/:recruiter_id' do
        halt(400, Errors::VERIFY_CORPORATE_SESSION) unless Auth.verify_corporate_session(env)

        recruiter = Recruiter.get(params[:recruiter_id])
        halt 404, Errors::RECRUITER_NOT_FOUND unless recruiter

        recruiter.destroy!

        ResponseFormat.data(Recruiter.all(order: [ :company_name.asc ]))
      end
    end
  end

  register RecruitersRoutes
end
