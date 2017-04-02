require 'spec_helper'

RSpec.describe Auth do
  let(:token) { "RANDOMTOKEN" }
  let(:netid) { "jsmith2" }
  let(:access_key) { "REQUEST KEY" }    
  before do
    allow(Config)
      .to receive(:load_config)
      .and_return( JSON.parse({request_key: token, access_key: access_key }.to_json))

    allow_any_instance_of(Net::HTTP)
      .to receive(:request)
      .and_return(double(code: "200", body: {token: token, isValid: 'true' }.to_json))
  end
  
  describe 'self.verify_request' do
    it 'should verify the token on the header' do
      get "/status", {}, { "HTTP_AUTHORIZATION" => "#{token}" }

      expect(last_response).to be_ok
    end
  end

  describe 'self.verify_corporate' do
    it 'should make a post request to the right service' do
      get "/status/corporate", {}, { "HTTP_AUTHORIZATION" => "Basic #{token}", "HTTP_NETID" => netid }

      expect(last_response).to be_ok
    end
  end
  
  describe 'self.verify_session' do
    it 'should make a post request to the right service' do
      get "/status/session", {}, { "HTTP_AUTHORIZATION" => "Basic #{token}", "HTTP_TOKEN" => token }

      expect(last_response).to be_ok
    end
  end
end