require 'spec_helper'

RSpec.describe Sinatra::RecruitersRoutes do
  let(:email) { "someemail@gmail.com" }
  let(:password) { "foo" }

  before :each do
    expect(Auth).to receive(:verify_request).and_return(true)
    allow(Auth).to receive(:verify_active_session).and_return(true)
  end

  describe "POST /recruiters/login" do
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
        post "/recruiters/login", { email: email, password: password}.to_json

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
  end

  describe "POST /recruiters/:recruiter_id/reset_password" do
  end

  describe "PUT /recruiters/:recruiter_id" do
  end
end   