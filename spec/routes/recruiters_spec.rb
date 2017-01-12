require 'spec_helper'

RSpec.describe Sinatra::RecruitersRoutes do
  def match_recruiter(datum, recruiter)
    expect(recruiter.first_name).to eq datum['first_name']
    expect(recruiter.last_name).to eq datum['last_name']
    expect(recruiter.company_name).to eq datum['company_name']
    expect(recruiter.type).to eq datum['type']
  end

  let(:password) { "foo" }
  let!(:recruiter) {
    Recruiter.create(
      first_name: "Steve",
      last_name: "Jobs",
      email: "steve@apple.com",
      company_name: "Apple",
      encrypted_password: Encrypt.encrypt_password(password),
      type: "Outreach"
    )
  }

  before :each do
    expect(Auth).to receive(:verify_request).and_return(true)
    allow(Auth).to receive(:verify_corporate_session).and_return(true)

    allow(Mailer).to receive(:email).and_return(true)
  end

  describe "GET /recruiters" do
    context 'for invalid parameters' do
      it 'should not allow a non-corporate user to access this route' do
        allow(Auth).to receive(:verify_corporate_session).and_return(false)

        get "/recruiters", {}.to_json

        expect(last_response).not_to be_ok
        json_data = JSON.parse(last_response.body)
        expect_error(json_data, Errors::VERIFY_CORPORATE_SESSION)
      end
    end

    it 'should return all recruiters' do
      get "/recruiters"

      expect(last_response).to be_ok
      json_data = JSON.parse(last_response.body)
      expect(json_data['data'].count).to eq 1
      match_recruiter(json_data['data'][0], recruiter)
    end
  end

  describe "POST /recruiters/login" do
    let(:email) { "someemail@gmail.com" }

    context 'for invalid params' do
      include_examples "invalid parameters", [:email, :password], "/recruiters/login", "post"
    end
    
    context 'when email is invalid' do
      it 'should return 400' do
        post "/recruiters/login", { email: email, password: password }.to_json

        expect(last_response.status).to eq 400
        json_data = JSON.parse(last_response.body)
        expect(json_data['error']).to eq("Invalid credentials")
      end
    end

    context 'when email and password are valid' do
      let(:first_name) { "John" }
      let(:last_name) { "Smith" }
      let(:company_name) { "UIUC" }
      
      before do
        @recruiter = Recruiter.create(
          first_name: first_name,
          last_name: last_name,
          company_name: company_name,
          email: email,
          encrypted_password: Encrypt.encrypt_password(password),
          expires_on: Date.today.next_year,
          type: "Outreach"
        )
      end

      it 'should return the recruiter information' do
        post "/recruiters/login", { email: email, password: password }.to_json

        expect(last_response).to be_ok
        json_data = JSON.parse(last_response.body)
        expect(json_data['error']).to be_nil
        expect(json_data['data']['first_name']).to eq first_name
        expect(json_data['data']['last_name']).to eq last_name
        expect(json_data['data']['company_name']).to eq company_name
      end

      it 'should return an encoded JWT token' do
        expect(JWT).to receive(:encode).and_return "ENCODED TOKEN"
        
        post "/recruiters/login", { email: email, password: password }.to_json
        
        expect(last_response).to be_ok
        json_data = JSON.parse(last_response.body)
        expect(json_data['data']['token']).to eq "ENCODED TOKEN"
      end

      context 'when recruiter account has expired' do
        it 'should return 400' do
          @recruiter.update(expires_on: Date.today - 1)

          post "/recruiters/login", { email: email, password: password }.to_json

          expect(last_response.status).to eq(400)
          json_data = JSON.parse(last_response.body)
          expect_error(json_data, Errors::ACCOUNT_EXPIRED)
        end
      end
    end
  end

  describe "POST /recruiters" do
    let(:valid_params) {
      {
        first_name: "Steve",
        last_name: "Wozniak",
        recruiter_email: "wozniak@fake.com",
        company_name: "Apple",
        type: "Outreach",
        email: "senderemail@gmail.com"
      }
    }
    
    context 'with invalid params' do
      # Don't check type here, but check invalid separately
      include_examples "invalid parameters", [:first_name, :last_name, :company_name, :recruiter_email, :email], "/recruiters", "post"

      it 'should not create the recruiter if type is invalid' do
        valid_params[:type] = "Invalid type"

        post '/recruiters', valid_params.to_json
        expect(last_response).not_to be_ok
      end
    end

    context 'with valid params' do
      context 'for a non-sponsor recruiter' do
        it 'should create the recruiter' do
          post '/recruiters', valid_params.to_json
          
          expect(last_response).to be_ok
          match_recruiter(JSON.parse(valid_params.to_json), Recruiter.last)
        end

        it 'should not send the email' do
          expect(Mailer).not_to receive(:email)

          post '/recruiters', @valid_params.to_json
        end
      end

      context 'for a sponsor recruiter' do
        before do
          valid_params[:type] = "Sponsor"
        end
        
        it 'should create the recruiter' do
          # TODO figure out why this test fails when it shouldn't be.
          post '/recruiters', valid_params.to_json
          
          expect(last_response).to be_ok
          match_recruiter(JSON.parse(valid_params.to_json), Recruiter.last)
        end

        it 'should send the email' do
          expect(Mailer).to receive(:email)

          post '/recruiters', valid_params.to_json
        end
      end
    end
  end

  describe "GET /recruiters/:recruiter_id" do
    it 'should return an error if the corporate session cannot be verified' do
      allow(Auth).to receive(:verify_corporate_session).and_return(false)

      get "/recruiters/#{recruiter.id}"
      expect(last_response).not_to be_ok
      json_response = JSON.parse(last_response.body)
      expect(json_response.to_json).to eq Errors::VERIFY_CORPORATE_SESSION
    end

    it 'should return an error if it cannot find a recruiter by id' do
      get "/recruiters/12345"

      expect(last_response).not_to be_ok
      json_response = JSON.parse(last_response.body)
      expect(json_response.to_json).to eq Errors::RECRUITER_NOT_FOUND
    end

    it 'should find a recruiter by id' do
      get "/recruiters/#{recruiter.id}"

      expect(last_response).to be_ok
      json_response = JSON.parse(last_response.body)
      expect(json_response["data"].to_json).to eq(recruiter.serialize.to_json)
    end
  end

  describe "PUT /recruiters/:recruiter_id" do
    let(:new_first_name) { "new first name" }
    let(:payload) {
      {
        first_name: new_first_name,
        last_name: recruiter.last_name,
        email: recruiter.email,
        type: recruiter.type
      }
    }

    context 'for invalid parameters' do
      include_examples "invalid parameters", [:first_name, :last_name, :email, :type], "/recruiters/1", "put"
    end

    it 'should return an error if the recruiter does not exist' do
      put "/recruiters/12345", payload.to_json

      expect(last_response).not_to be_ok
      json_data = JSON.parse(last_response.body)
      expect_error(json_data, Errors::RECRUITER_NOT_FOUND)
    end

    it 'should update the recruiters information' do
      put "/recruiters/#{recruiter.id}", payload.to_json
      expect(last_response).to be_ok
      expect(Recruiter.last.first_name).to eq new_first_name
    end
  end

  describe "POST /recruiters/reset_password" do
    let(:valid_params) {
      {
        first_name: recruiter.first_name,
        last_name: recruiter.last_name,
        recruiter_email: recruiter.email,
        email: "senderemail@gmail.com"
      }
    }

    context 'for invalid parameters' do
      include_examples "invalid parameters", [:first_name, :last_name, :recruiter_email, :email], "/recruiters/reset_password", "post"

      it 'should return an error if the recruiter does not exist' do
        valid_params[:first_name] = "Invalid"
        post "/recruiters/reset_password", valid_params.to_json

        expect(last_response).not_to be_ok
        json_data = JSON.parse(last_response.body)
        expect_error(json_data, Errors::INCORRECT_RESET_CREDENTIALS)
      end
    end

    context 'for a non-sponsor recruiter' do
      it 'should return an error' do
        post "/recruiters/reset_password", valid_params.to_json
        
        expect(last_response).not_to be_ok
      end
    end

    context 'for a sponsor recruiter' do
      before do
        recruiter.update(type: "Sponsor")
      end

      it 'should generate a new password' do
        new_encrypted_password = "new_encrypted_password"
        expect(Encrypt)
          .to receive(:generate_encrypted_password)
          .and_return([new_encrypted_password, new_encrypted_password])
        
        post "/recruiters/reset_password", valid_params.to_json

        expect(Recruiter.last.encrypted_password).to eq new_encrypted_password
      end

      it 'should send an email to the recruiter' do
        expect(Mailer).to receive(:email)

        post "/recruiters/reset_password", valid_params.to_json
      end
    end
  end

  describe "GET /recruiters/:recruiter_id/invite" do
    it 'should return an error if the corporate session cannot be verified' do
      allow(Auth).to receive(:verify_corporate_session).and_return(false)

      get "/recruiters/#{recruiter.id}/invite"
      expect(last_response).not_to be_ok
      json_response = JSON.parse(last_response.body)
      expect(json_response.to_json).to eq Errors::VERIFY_CORPORATE_SESSION
    end

    it 'should return an error if it cannot find a recruiter by id' do
      get "/recruiters/12345/invite"

      expect(last_response).not_to be_ok
      json_response = JSON.parse(last_response.body)
      expect(json_response.to_json).to eq Errors::RECRUITER_NOT_FOUND
    end

    it 'should fetch a recruiters invitation for Outreach' do
      get "/recruiters/#{recruiter.id}/invite"

      expect(last_response).to be_ok
      json_response = JSON.parse(last_response.body)

      expect(json_response["data"]["subject"]).to eq "#{recruiter.company_name} ACM@UIUC"
      expect(json_response["data"]["to"]).to eq recruiter.email
      expect(json_response["data"]["recruiter"].to_json).to eq recruiter.serialize.to_json
    end
  end

  describe "POST /recruiters/:recruiter_id/invite" do
    let(:valid_params) {
      {
        to: recruiter.email,
        subject: "Subject",
        body: "Message",
        email: "senderemail@gmail.com"
      }
    }

    context 'for invalid parameters' do
      include_examples "invalid parameters", [:to, :subject, :body, :email], "/recruiters/1/invite", "post"

      it 'should return an error if the corporate session cannot be verified' do
        allow(Auth).to receive(:verify_corporate_session).and_return(false)

        post "/recruiters/#{recruiter.id}/invite", valid_params.to_json
        expect(last_response).not_to be_ok
        json_response = JSON.parse(last_response.body)
        expect(json_response.to_json).to eq Errors::VERIFY_CORPORATE_SESSION
      end

      it 'should return an error if it cannot find a recruiter by id' do
        post "/recruiters/12345/invite", valid_params.to_json

        expect(last_response).not_to be_ok
        json_response = JSON.parse(last_response.body)
        expect(json_response.to_json).to eq Errors::RECRUITER_NOT_FOUND
      end
    end

    context 'for valid params' do
      it 'should send the email' do
        expect(Mailer).to receive(:email)

        post "/recruiters/#{recruiter.id}/invite", valid_params.to_json
        expect(last_response).to be_ok
      end

      it 'should set invited attribute to true' do
        expect(recruiter.invited).to eq false
        
        post "/recruiters/#{recruiter.id}/invite", valid_params.to_json
        expect(last_response).to be_ok
        expect(Recruiter.last.invited).to eq true
      end
    end
  end

  describe "PUT /recruiters/:recruiter_id/renew" do
    context 'for invalid parameters' do
      it 'should not allow a non-corporate user to access this route' do
        allow(Auth).to receive(:verify_corporate_session).and_return(false)

        put "/recruiters/#{recruiter.id}/renew", {}.to_json

        expect(last_response).not_to be_ok
        json_data = JSON.parse(last_response.body)
        expect_error(json_data, Errors::VERIFY_CORPORATE_SESSION)
      end

      it 'should return an error if the recruiter does not exist' do
        put "/recruiters/#{recruiter.id}1/renew", {}.to_json

        expect(last_response).not_to be_ok
        json_data = JSON.parse(last_response.body)
        expect_error(json_data, Errors::RECRUITER_NOT_FOUND)
      end
    end

    context 'for valid parameters' do
      it 'should extend a recruiters expiration date by exactly one year from its current expiration date' do
        current_expiration_date = recruiter.expires_on
        expected_expiration_date = current_expiration_date.next_year

        put "/recruiters/#{recruiter.id}/renew", {}.to_json
        expect(last_response).to be_ok

        expect(Recruiter.last.expires_on).to eq(expected_expiration_date)

        json_data = JSON.parse(last_response.body)
        expect(json_data['data'].count).to eq 1
        match_recruiter(json_data['data'][0], recruiter)
      end
    end
  end

  describe "POST /recruiters/reset" do
    context 'for invalid parameters' do
      it 'should not allow a non-corporate user to access this route' do
        allow(Auth).to receive(:verify_corporate_session).and_return(false)

        post "/recruiters/reset", {}.to_json

        expect(last_response).not_to be_ok
        json_data = JSON.parse(last_response.body)
        expect_error(json_data, Errors::VERIFY_CORPORATE_SESSION)
      end
    end

    context 'for valid parameters' do
      it 'should set all the recruiters invited status to false' do
        post "/recruiters/reset", {}.to_json
        expect(last_response).to be_ok
        expect(Recruiter.all.map(&:invited)).to all(be false)
      end
    end
  end

  describe "DELETE /recruiters/:recruiter_id" do
    context 'for invalid parameters' do
      it 'should not allow a non-corporate user to access this route' do
        allow(Auth).to receive(:verify_corporate_session).and_return(false)

        delete "/recruiters/#{recruiter.id}", {}.to_json

        expect(last_response).not_to be_ok
        json_data = JSON.parse(last_response.body)
        expect_error(json_data, Errors::VERIFY_CORPORATE_SESSION)
      end

      it 'should return an error if the recruiter does not exist' do
        delete "/recruiters/#{recruiter.id}1", {}.to_json

        expect(last_response).not_to be_ok
        json_data = JSON.parse(last_response.body)
        expect_error(json_data, Errors::RECRUITER_NOT_FOUND)
      end
    end

    context 'for valid parameters' do
      it 'should delete the recruiter successfully' do
        # Ensure the recruiter is in the database before, and not after
        expect(Recruiter.last).to eq recruiter

        delete "/recruiters/#{recruiter.id}", {}.to_json

        expect(last_response).to be_ok
        expect(Recruiter.last).to be_nil
      end
    end
  end
end