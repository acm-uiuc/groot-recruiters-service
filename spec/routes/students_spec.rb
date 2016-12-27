require 'spec_helper'

RSpec.describe Sinatra::StudentsRoutes do
  let(:access_token) { "FAKE ACCESS TOKEN" }
  let(:netid) { "FAKE RANDOM ADMIN USER" }

  before :each do
    expect(Auth).to receive(:verify_token).and_return(true)
    allow(Auth).to receive(:verify_admin).and_return(true)
  end

  context 'without parameters' do
    it 'should return a 200' do
      get "/students", {}
      
      expect(last_response).to be_ok
      json_data = JSON.parse(last_response.body)
      expect(json_data['data']).to eq([])
    end

    it 'should return all students' do
      student = Student.create(
        first_name: "John",
        last_name: "Smith",
        email: "johnsmith@gmail.com",
        graduation_date: Date.today.next_year,
        degree_type: "Bachelors",
        job_type: "Full-Time",
        netid: "jsmith2",
        active: true
      )

      get "/students", {}
      
      expect(last_response).to be_ok
      json_data = JSON.parse(last_response.body)
      expect(json_data['error']).to be_nil
      expect(json_data['data'][0]['first_name']).to eq(student.first_name)
      expect(json_data['data'][0]['last_name']).to eq(student.last_name)
      expect(json_data['data'][0]['netid']).to eq(student.netid)
    end
  end
end