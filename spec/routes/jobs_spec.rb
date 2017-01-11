require 'spec_helper'

RSpec.describe Sinatra::JobsRoutes do
  before :each do
    expect(Auth).to receive(:verify_request).and_return(true)
    allow(Auth).to receive(:verify_corporate_session).and_return(true)
  end

  def match_job(datum, job)
    expect(job.title).to eq datum['title']
    expect(job.company).to eq datum['company']
    expect(job.contact_name).to eq datum['contact_name']
  end
  
  let(:job) {
    Job.create(
      title: "Software Engineer",
      company: "Apple",
      contact_name: "Steve Jobs",
      contact_email: "banana@apple.com",
      contact_phone: "111-111-1111",
      job_type: "Full-Time",
      description: "You work at Apple."
    )
  }

  describe "GET /jobs" do
    it 'should return a 200' do
      get "/jobs"
      expect(last_response).to be_ok
    end

    it 'should return all unapproved jobs' do
      job1 = Job.create(
        title: "Software Engineer",
        company: "Apple",
        contact_name: "Steve Jobs",
        contact_email: "banana@apple.com",
        contact_phone: "111-111-1111",
        job_type: "Full-Time",
        description: "You work at Apple.",
        approved: true
      )

      job2 = Job.create(
        title: "Fake Software Engineer",
        company: "Apple",
        contact_name: "Steve Jobs",
        contact_email: "banana@apple.com",
        contact_phone: "111-111-1111",
        job_type: "Internship",
        description: "You work at Apple."
      )

      get "/jobs"
      expect(last_response).to be_ok
      json_data = JSON.parse(last_response.body)
      expect(json_data['data'].count).to eq 1

      match_job(json_data['data'][0], job2)
    end
  end

  describe "POST /jobs" do
    before do
      @valid_params = {
        job_title: "Software Engineer",
        organization: "Apple",
        contact_name: "Steve Jobs",
        contact_email: "banana@apple.com",
        contact_phone: "111-111-1111",
        job_type: "Full-Time",
        description: "You work at Apple."
      }
    end

    context 'with invalid params' do
      [:job_title, :organization, :contact_name, :contact_email, :contact_phone, :job_type, :description].each do |key|
        it "should not create the job and return an error when #{key} is missing" do
          @valid_params.delete(key)

          post '/jobs', @valid_params.to_json

          expect(last_response).not_to be_ok
          json_data = JSON.parse(last_response.body)
          expect(json_data['error']).to eq "Missing #{key}"
        end
      end
    end

    context 'with valid params' do
      it 'should create the job successfully' do
        post '/jobs', @valid_params.to_json

        expect(last_response).to be_ok
      end
    end
  end

  describe "PUT /jobs/:job_id/approve" do
    it 'should not allow a non-corporate user to access this route' do
      allow(Auth).to receive(:verify_corporate_session).and_return(false)

      put "/jobs/#{job.id}/approve"
      expect(last_response).not_to be_ok
      json_data = JSON.parse(last_response.body)
      expect_error(json_data, Errors::VERIFY_CORPORATE_SESSION)
    end

    it 'should approve an unapproved job' do
      
      expect(job.approved).to eq false
  
      put "/jobs/#{job.id}/approve", {}.to_json
      expect(last_response).to be_ok
      expect(Job.last.approved).to eq true

      json_data = JSON.parse(last_response.body)
      expect(json_data['data'].count).to eq 0
    end
    
    it 'should not approve a job which has already been approved' do
      job.update(approved: true)

      put "/jobs/#{job.id}/approve"

      expect(last_response).not_to be_ok
      json_data = JSON.parse(last_response.body)
      # expect(json_data['error']).to eq "Job already approved"
      expect_error(json_data, Errors::JOB_APPROVED)
    end
  end

  describe "DELETE /jobs/:job_id" do
    it 'should not allow a non-corporate user to access this route' do
      allow(Auth).to receive(:verify_corporate_session).and_return(false)

      delete "/jobs/#{job.id}"
      expect(last_response).not_to be_ok
      json_data = JSON.parse(last_response.body)
      expect_error(json_data, Errors::VERIFY_CORPORATE_SESSION)
    end

    it 'should return an error if it cannot find the job by id' do
      delete "/jobs/#{job.id}1"

      expect(last_response).not_to be_ok
    end

    it 'should delete the job by netid' do
      delete "/jobs/#{job.id}"

      expect(last_response).to be_ok
      expect(Job.last).to be_nil
    end
  end
end