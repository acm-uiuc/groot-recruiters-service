require 'spec_helper'

RSpec.describe Sinatra::StudentsRoutes do
  let(:access_token) { "FAKE ACCESS TOKEN" }
  let(:netid) { "FAKE RANDOM ADMIN USER" }

  before :each do
    expect(Auth).to receive(:verify_token).and_return(true)
    allow(Auth).to receive(:verify_admin).and_return(true)
  end

  context 'without parameters' do
    let(:params) { nil }

    it 'should return a 200' do
      get "/students", params, { "Authorization" => access_token, "NETID" => netid }
      
      expect(last_response.status).to eq 200
    end
  end
end