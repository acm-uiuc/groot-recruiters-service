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
        halt 401, Errors::VERIFY_CORPORATE_SESSION unless Auth.verify_corporate_session(env)

        conditions = {}.tap do |conditions|
          conditions[:type] = params[:type] if params[:type] && Recruiter.validate(params, [:type])
          conditions[:order] = [ :company_name.asc ]
        end

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
        
        jwt_secret = Config.load_config("jwt")["secret"]
        token = JWT.encode recruiter.serialize, jwt_secret, 'HS256'
        
        response = JSON.parse(ResponseFormat.data(recruiter))
        response["data"]["token"] = token
        response.to_json
      end

      app.post '/recruiters' do
        halt 401, Errors::VERIFY_CORPORATE_SESSION unless Auth.verify_corporate_session(env)

        params = ResponseFormat.get_params(request.body.read)

        status, error = Recruiter.validate(params, [:company_name, :first_name, :last_name, :email, :type])
        halt status, ResponseFormat.error(error) if error

        # Recruiter with these parameters should not exist already
        existing_recruiter = Recruiter.first(email: params[:email])
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
          ResponseFormat.message("Created account for #{r.company_name} in our database")
        else
          halt 400, ResponseFormat.error("Failed to create an account for #{r.company_name} in our database")
        end
      end

      app.get '/recruiters/:recruiter_id' do
        halt 401, Errors::VERIFY_CORPORATE_SESSION unless Auth.verify_corporate_session(env)
        
        recruiter = Recruiter.get(params[:recruiter_id]) || halt(404, Errors::RECRUITER_NOT_FOUND)
        ResponseFormat.data(recruiter)
      end
      
      app.put '/recruiters/:recruiter_id' do
        halt 401, Errors::VERIFY_CORPORATE_SESSION unless Auth.verify_corporate_session(env)

        recruiter_id = params[:recruiter_id]
        params = ResponseFormat.get_params(request.body.read)
        params[:recruiter_id] = recruiter_id

        status, error = Recruiter.validate(params, [:recruiter_id, :email, :first_name, :last_name, :type])
        halt status, ResponseFormat.error(error) if error
        
        recruiter = Recruiter.get(params[:recruiter_id])
        halt(404, Errors::RECRUITER_NOT_FOUND) unless recruiter
        
        sponsor_before = recruiter.is_sponsor?
        recruiter.update(
          first_name: params[:first_name],
          last_name: params[:last_name],
          email: params[:email],
          type: params[:type]
        )
        sponsor_now = recruiter.is_sponsor?
        
        message = "Recruiter updated successfully"
        if !sponsor_before && sponsor_now
          # Given resume access now
          random_password, encrypted = Encrypt.generate_encrypted_password
          recruiter.update(encrypted_password: encrypted)
          
          subject = '[Corporate-l] ACM@UIUC Resume Book'
          html_body = erb :new_account_email, locals: { recruiter: recruiter, password: random_password }
          Mailer.email(subject, html_body, recruiter.email)

          message = "#{recruiter.first_name} has been granted access to the resume book"
        elsif sponsor_before && !sponsor_now
          # Resume access was revoked
          recruiter.update(encrypted_password: nil)
          message = "#{recruiter.first_name}'s access to the resume book has been revoked"
        end
        ResponseFormat.message(message)
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
          halt 500, ERRORS::EMAIL_ERROR
        end
      end
      
      app.get '/recruiters/:recruiter_id/invite' do
        halt 401, Errors::VERIFY_CORPORATE_SESSION unless Auth.verify_corporate_session(env)

        recruiter = Recruiter.get(params[:recruiter_id])
        halt 404, Errors::RECRUITER_NOT_FOUND unless recruiter

        # Username will also be optionally sent from the UI
        invitation = Invitation.new(recruiter, params[:username] || "ENTER YOUR NAME HERE")
        ResponseFormat.data(invitation)
      end

      app.post '/recruiters/:recruiter_id/invite' do
        halt 401, Errors::VERIFY_CORPORATE_SESSION unless Auth.verify_corporate_session(env)

        recruiter_id = params[:recruiter_id]
        params = ResponseFormat.get_params(request.body.read)
        status, error = Recruiter.validate(params, [:to, :subject, :body])
        halt status, ResponseFormat.error(error) if error
        params[:recruiter_id] = recruiter_id

        recruiter = Recruiter.get(params[:recruiter_id])
        halt 404, Errors::RECRUITER_NOT_FOUND unless recruiter
        halt 400, ResponseFormat.error("Recruiter was already invited") if recruiter.invited

        if Mailer.email(params[:subject], params[:body], params[:to])
          recruiter.update(invited: true)
          ResponseFormat.message("Sent #{params[:to]} an email")
        else
          halt 500, ResponseFormat.error("Failed to send email to #{params[:to]}")
        end
      end

      app.put '/recruiters/:recruiter_id/renew' do
        halt 401, Errors::VERIFY_CORPORATE_SESSION unless Auth.verify_corporate_session(env)

        recruiter = Recruiter.get(params[:recruiter_id])
        halt 404, Errors::RECRUITER_NOT_FOUND unless recruiter

        recruiter.update(expires_on: recruiter.expires_on.next_year)

        ResponseFormat.data(Recruiter.all(order: [ :company_name.asc ]))
      end

      app.post '/recruiters/reset' do
        halt 401, Errors::VERIFY_CORPORATE_SESSION unless Auth.verify_corporate_session(env)

        Recruiter.update(invited: false)

        ResponseFormat.message("Reset all recruiter invitations. You can now invite recruiters to job fairs")
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
