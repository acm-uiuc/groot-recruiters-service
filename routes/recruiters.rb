# Copyright © 2017, ACM@UIUC
#
# This file is part of the Groot Project.
#
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
# encoding: UTF-8

module Sinatra
  module RecruitersRoutes
    def self.registered(app)
      app.get '/recruiters' do
        halt 401, Errors::VERIFY_ADMIN_SESSION unless Auth.verify_admin_session(env)

        conditions = {}.tap do |c|
          c[:type] = params[:type] if params[:type] && Recruiter.validate(params, [:type])
          c[:order] = [:company_name.asc]
        end

        matching_recruiters = Recruiter.all(conditions)
        ResponseFormat.data(matching_recruiters)
      end

      app.post '/recruiters/login' do
        params = ResponseFormat.get_params(request.body.read)

        status, error = Recruiter.validate(params, %i[email password])
        halt status, ResponseFormat.error(error) if error

        recruiter = Recruiter.first(email: params[:email])
        halt 400, Errors::INVALID_CREDENTIALS unless recruiter

        encrypted_password = recruiter.encrypted_password
        halt 400, Errors::INELIGIBLE_ACCOUNT unless encrypted_password

        correct_credentials = Encrypt.valid_password?(encrypted_password, params[:password])
        halt 400, Errors::INVALID_CREDENTIALS unless correct_credentials
        halt 400, Errors::ACCOUNT_EXPIRED if recruiter.expires_on < Date.today

        jwt_secret = Config.load_config('jwt')['secret']
        token = JWT.encode recruiter.serialize, jwt_secret, 'HS256'

        response = JSON.parse(ResponseFormat.data(recruiter))
        response['data']['token'] = token
        response.to_json
      end

      app.post '/recruiters' do
        halt 401, Errors::VERIFY_ADMIN_SESSION unless Auth.verify_admin_session(env)

        params = ResponseFormat.get_params(request.body.read)

        status, error = Recruiter.validate(params, %i[company_name first_name last_name recruiter_email email type])
        halt status, ResponseFormat.error(error) if error

        # Recruiter with these parameters should not exist already
        existing_recruiter = Recruiter.first(email: params[:recruiter_email])
        halt 400, Errors::DUPLICATE_ACCOUNT if existing_recruiter

        r = Recruiter.new
        r.company_name = params[:company_name]
        r.first_name = params[:first_name]
        r.last_name = params[:last_name]
        r.email = params[:recruiter_email]
        r.type = params[:type]
        random_password, encrypted = Encrypt.generate_encrypted_password
        r.encrypted_password = encrypted if r.sponsor?
        r.expires_on = Date.today.next_year # Other recruiters will have their credentials later.

        subject = '[Corporate-l] ACM@UIUC: Resume Book'
        html_body = erb :new_account_email, locals: { recruiter: r, password: random_password }

        # Only email sponsor recruiters, but save all recruiters
        if !r.sponsor? || Mailer.email(subject, html_body, params[:email], params[:recruiter_email])
          r.save
          ResponseFormat.message("Created account for #{r.company_name} in our database")
        else
          halt 400, ResponseFormat.error("Failed to create an account for #{r.company_name} in our database")
        end
      end

      app.get '/recruiters/:recruiter_id' do
        halt 401, Errors::VERIFY_ADMIN_SESSION unless Auth.verify_admin_session(env)

        recruiter = Recruiter.get(params[:recruiter_id]) || halt(404, Errors::RECRUITER_NOT_FOUND)
        ResponseFormat.data(recruiter)
      end

      app.put '/recruiters/:recruiter_id' do
        halt 401, Errors::VERIFY_ADMIN_SESSION unless Auth.verify_admin_session(env)

        recruiter_id = params[:recruiter_id]
        params = ResponseFormat.get_params(request.body.read)
        params[:recruiter_id] = recruiter_id

        status, error = Recruiter.validate(params, %i[recruiter_id email first_name last_name type email])
        halt status, ResponseFormat.error(error) if error

        recruiter = Recruiter.get(params[:recruiter_id])
        halt(404, Errors::RECRUITER_NOT_FOUND) unless recruiter

        recruiter.update(
          first_name: params[:first_name],
          last_name: params[:last_name],
          email: params[:email],
          type: params[:type]
        )

        ResponseFormat.message('Recruiter updated successfully')
      end

      app.post '/recruiters/reset_password' do
        params = ResponseFormat.get_params(request.body.read)

        status, error = Recruiter.validate(params, %i[first_name last_name recruiter_email email])
        halt status, ResponseFormat.error(error) if error

        recruiter = Recruiter.first(first_name: params[:first_name],
                                    last_name: params[:last_name],
                                    email: params[:recruiter_email])
        halt 404, Errors::INCORRECT_RESET_CREDENTIALS unless recruiter

        # Generate new password
        random_password, encrypted = Encrypt.generate_encrypted_password
        recruiter.encrypted_password = encrypted

        subject = '[Corporate-l] ACM@UIUC: New Password Request'
        html_body = erb :forgot_password_email, locals: { recruiter: recruiter, password: random_password }

        if Mailer.email(subject, html_body, params[:email], params[:recruiter_email])
          recruiter.save
          ResponseFormat.message('We have verified your account details. Check your email for a new password.')
        else
          halt 500, Errors::EMAIL_ERROR
        end
      end

      app.get '/recruiters/:recruiter_id/invite' do
        halt 401, Errors::VERIFY_ADMIN_SESSION unless Auth.verify_admin_session(env)

        recruiter = Recruiter.get(params[:recruiter_id])
        halt 404, Errors::RECRUITER_NOT_FOUND unless recruiter

        # Sanity check, Sponsor recruiters should not be getting an invitation
        halt 500, ResponseFormat.error('Sponsor recruiters cannot request an invite') if recruiter.sponsor?

        random_password, encrypted = Encrypt.generate_encrypted_password
        recruiter.update(encrypted_password: encrypted)

        # Username will also be optionally sent from the UI
        invitation = Invitation.new(recruiter, params[:username] || 'person', random_password)
        ResponseFormat.data(invitation)
      end

      app.post '/recruiters/:recruiter_id/invite' do
        halt 401, Errors::VERIFY_ADMIN_SESSION unless Auth.verify_admin_session(env)

        recruiter_id = params[:recruiter_id]
        params = ResponseFormat.get_params(request.body.read)
        status, error = Recruiter.validate(params, %i[to subject body email])
        halt status, ResponseFormat.error(error) if error
        params[:recruiter_id] = recruiter_id

        recruiter = Recruiter.get(params[:recruiter_id])
        halt 404, Errors::RECRUITER_NOT_FOUND unless recruiter
        halt 400, ResponseFormat.error('Recruiter was already invited') if recruiter.invited

        if Mailer.email(params[:subject], params[:body], params[:email], params[:to], params[:ccs])
          recruiter.update(invited: true)
          ResponseFormat.message("Sent #{params[:to]} an email")
        else
          halt 500, ResponseFormat.error("Failed to send email to #{params[:to]}")
        end
      end

      app.put '/recruiters/:recruiter_id/renew' do
        halt 401, Errors::VERIFY_ADMIN_SESSION unless Auth.verify_admin_session(env)

        recruiter = Recruiter.get(params[:recruiter_id])
        halt 404, Errors::RECRUITER_NOT_FOUND unless recruiter

        recruiter.update(expires_on: recruiter.expires_on.next_year)
        ResponseFormat.data(Recruiter.all(order: [:company_name.asc]))
      end

      app.post '/recruiters/reset' do
        halt 401, Errors::VERIFY_ADMIN_SESSION unless Auth.verify_admin_session(env)

        Recruiter.update(invited: false)
        ResponseFormat.message('Reset all recruiter invitations. You can now invite recruiters to fairs again')
      end

      app.delete '/recruiters/:recruiter_id' do
        halt(400, Errors::VERIFY_ADMIN_SESSION) unless Auth.verify_admin_session(env)

        recruiter = Recruiter.get(params[:recruiter_id])
        halt 404, Errors::RECRUITER_NOT_FOUND unless recruiter

        recruiter.destroy!
        ResponseFormat.data(Recruiter.all(order: [:company_name.asc]))
      end
    end
  end

  register RecruitersRoutes
end
