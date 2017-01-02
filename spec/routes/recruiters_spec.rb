require 'spec_helper'

RSpec.describe Sinatra::RecruitersRoutes do
  def match_recruiter(datum, recruiter)
    expect(recruiter.first_name).to eq datum['first_name']
    expect(recruiter.last_name).to eq datum['last_name']
    expect(recruiter.email).to eq datum['email']
    expect(recruiter.company_name).to eq datum['company_name']
  end

  let(:password) { "foo" }
  let!(:recruiter) {
    Recruiter.create!(
      first_name: "Steve",
      last_name: "Jobs",
      email: "steve@apple.com",
      company_name: "Apple",
      encrypted_password: Encrypt.encrypt_password(password)
    )
  }


  before :each do
    expect(Auth).to receive(:verify_request).and_return(true)
    allow(Auth).to receive(:verify_session).and_return(true)

    allow(Mailer).to receive(:email).and_return(true)
  end

  describe "GET /recruiters" do
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

    context 'when email is missing' do
      it 'should return 400' do
        post "/recruiters/login"

        expect(last_response.status).to eq(400)
        json_data = JSON.parse(last_response.body)
        expect(json_data['error']).to eq("Missing email")
      end
    end

    context 'when password is missing' do
      it 'should return 400' do
        post "/recruiters/login", { email: email }.to_json

        expect(last_response.status).to eq(400)
        json_data = JSON.parse(last_response.body)
        expect(json_data['error']).to eq("Missing password")
      end
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
          expires_on: Date.today.next_year
        )
      end

      it 'should return the recruiter information' do
        post "/recruiters/login", { email: email, password: password }.to_json

        expect(last_response).to be_ok
        json_data = JSON.parse(last_response.body)
        expect(json_data['error']).to be_nil
        expect(json_data['data']['first_name']).to eq(first_name)
        expect(json_data['data']['last_name']).to eq(last_name)
        expect(json_data['data']['company_name']).to eq(company_name)
      end

      context 'when recruiter account has expired' do
        it 'should return 400' do
          @recruiter.update(expires_on: Date.today - 1)

          post "/recruiters/login", { email: email, password: password }.to_json

          expect(last_response.status).to eq(400)
          json_data = JSON.parse(last_response.body)
          expect(json_data['error']).to eq("Account has expired!")
        end
      end
    end
  end

  describe "POST /recruiters" do
    before do
      @valid_params = {
        first_name: "Steve",
        last_name: "Wozniak",
        email: "wozniak@fake.com",
        company_name: "Apple",
      }
    end
    
    context 'with invalid params' do
      [:first_name, :last_name, :company_name, :email].each do |key|
        it "should not create the recruiter and return an error when #{key} is missing" do
          @valid_params.delete(key)

          post '/recruiters', @valid_params.to_json

          expect(last_response).not_to be_ok
          json_data = JSON.parse(last_response.body)
          expect(json_data['error']).to eq "Missing #{key}"
        end
      end
    end

    context 'with valid params' do
      it 'should create the recruiter' do
        post '/recruiters', @valid_params.to_json
        
        expect(last_response).to be_ok
        match_recruiter(JSON.parse(@valid_params.to_json), Recruiter.last)
      end
    end
  end

  describe "POST /recruiters/:recruiter_id/reset_password" do
    it 'should return an error if the recruiter does not exist' do
      post "/recruiters/#{recruiter.id}1/reset_password"

      expect(last_response).not_to be_ok
      json_data = JSON.parse(last_response.body)
      expect(json_data['error']).to eq 'Recruiter not found'
    end

    it 'should generate a new password for the recruiter' do
      new_encrypted_password = "new_encrypted_password"
      expect(Encrypt)
        .to receive(:generate_encrypted_password)
        .and_return([new_encrypted_password, new_encrypted_password])

      post "/recruiters/#{recruiter.id}/reset_password"

      expect(Recruiter.last.encrypted_password).to eq new_encrypted_password
    end

    it 'should send an email to the recruiter' do
      expect(Mailer).to receive(:email)

      post "/recruiters/#{recruiter.id}/reset_password"
    end
  end

  describe "PUT /recruiters/:recruiter_id" do
    let(:payload) {
      {
        id: recruiter.id,
        email: recruiter.email,
        password: password,
        new_password: "foobar"
      }
    }

    it 'should return an error if the recruiter does not exist' do
      put "/recruiters/#{recruiter.id}1", payload.to_json

      expect(last_response).not_to be_ok
      json_data = JSON.parse(last_response.body)
      expect(json_data['error']).to eq 'Invalid credentials'
    end

    it 'should update the password with the new_password' do
      expect(Encrypt)
        .to receive(:encrypt_password)
        .with(payload[:new_password])
        .and_return("encrypted foobar")
      
      put "/recruiters/#{recruiter.id}", payload.to_json

      expect(last_response).to be_ok

      expect(Recruiter.last.encrypted_password).to eq "encrypted foobar"
    end
  end

  describe "PUT /recruiters/:recruiter_id/renew" do
  end

  describe "DELETE /recruiters/:recruiter_id" do
  end
end   