require 'spec_helper'

RSpec.describe Sinatra::StudentsRoutes do
  def match_student(datum, student)
    expect(datum['first_name']).to eq student.first_name
    expect(datum['last_name']).to eq student.last_name
    expect(datum['netid']).to eq student.netid
  end

  before :each do
    allow(Auth).to receive(:verify_admin_session).and_return(true)
  end

  let!(:netid) { 'jsmith2' }
  let!(:student) {
    Student.create(
      first_name: 'John',
      last_name: 'Smith',
      netid: netid,
      email: "#{netid}@illinois.edu",
      graduation_date: Date.today.next_year,
      degree_type: 'Bachelors',
      job_type: 'Full-Time'
    )
  }
  let!(:uuid) { 'fake-uuid' }

  describe 'GET /students' do
    context 'for invalid authentication' do
      it 'should not allow a non-corporate user to access this route' do
        allow(Auth).to receive(:verify_admin_session).and_return(false)

        get '/students', {}.to_json

        expect(last_response).not_to be_ok
        json_data = JSON.parse(last_response.body)
        expect_error(json_data, Errors::VERIFY_ADMIN_SESSION)
      end
    end

    context 'for valid recruiter authentication' do
      it 'should return a 200' do
        allow(JWTAuth).to receive(:decode).and_return(
          id: 1,
          code: 200,
          first_name: 'Recruiter First Name',
          last_name: 'Recruiter Last Name'
        )

        get '/students', {}.to_json

        expect(last_response).to be_ok
        json_data = JSON.parse(last_response.body)
        expect(json_data['data']).to eq([])
      end
    end

    context 'without students' do
      it 'should return a 200' do
        get '/students', {}

        expect(last_response).to be_ok
        json_data = JSON.parse(last_response.body)
        expect(json_data['data']).to eq([])
      end
    end

    context 'with students' do
      it 'should only return approved students' do
        first_name = 'Jake'
        last_name = 'Smith'
        netid3 = 'jsmith3'
        approved_student = Student.create(
          first_name: first_name,
          last_name: last_name,
          email: 'jakesmith@gmail.com',
          graduation_date: Date.today.next_year,
          degree_type: 'Bachelors',
          job_type: 'Full-Time',
          netid: netid3,
          approved_resume: true
        )

        get '/students', {}

        expect(last_response).to be_ok
        json_data = JSON.parse(last_response.body)
        expect(json_data['data'].count).to eq 1
        match_student(json_data['data'][0], approved_student)
      end
    end

    context 'with a user' do
      let(:first_name) { 'Association' }
      let(:last_name) { 'Machinery' }
      let(:netid1) { 'acm2' }
      let(:netid2) { 'acm32' }

      let!(:student1) {
        Student.create(
          first_name: first_name,
          last_name: last_name,
          email: "#{netid1}@gmail.com",
          graduation_date: Date.today.next_year,
          degree_type: 'Bachelors',
          job_type: 'Full-Time',
          netid: netid1,
          approved_resume: true
        )
      }

      let!(:student2) {
        Student.create(
          first_name: first_name,
          last_name: last_name,
          email: "#{netid2}@gmail.com",
          graduation_date: Date.today.next_year,
          degree_type: 'Bachelors',
          job_type: 'Full-Time',
          netid: netid2,
          approved_resume: true
        )
      }

      it 'should return one student by his unique netid' do
        get '/students', netid: netid1

        expect(last_response).to be_ok
        json_data = JSON.parse(last_response.body)
        expect(json_data['data'].count).to eq 1
        match_student(json_data['data'][0], student1)
      end

      it 'should return all students by their first_name' do
        get '/students', first_name: first_name

        expect(last_response).to be_ok
        json_data = JSON.parse(last_response.body)
        expect(json_data['data'].count).to eq 2
        match_student(json_data['data'][0], student1)
        match_student(json_data['data'][1], student2)
      end

      it 'should return all students who will graduate after a certain date' do
        get '/students', graduationStart: Date.today.to_s

        expect(last_response).to be_ok
        json_data = JSON.parse(last_response.body)
        expect(json_data['data'].count).to eq 2
        match_student(json_data['data'][0], student1)
        match_student(json_data['data'][1], student2)
      end

      it 'should return all students who will graduate before a certain date' do
        get '/students', graduationEnd: (Date.today.next_year + 1).to_s

        expect(last_response).to be_ok
        json_data = JSON.parse(last_response.body)
        expect(json_data['data'].count).to eq 2
        match_student(json_data['data'][0], student1)
        match_student(json_data['data'][1], student2)
      end
    end
  end

  describe 'POST /students' do
    before do
      @valid_params = {
        netid: 'jsmith2',
        firstName: 'John',
        lastName: 'Smith',
        email: 'jsmith2@illinois.edu',
        gradYear: "December #{Date.today.next_year.year}",
        degreeType: 'Bachelors',
        jobType: 'Internship',
        resume: 'BASE64ENCODEDSTRING'
      }
    end

    context 'with invalid params' do
      %i[netid firstName lastName email gradYear degreeType jobType resume].each do |key|
        it "should not create the student and return an error when #{key} is missing" do
          @valid_params.delete(key)

          post '/students', @valid_params.to_json

          expect(last_response).not_to be_ok
          json_data = JSON.parse(last_response.body)
          expect(json_data['error']).to eq "Missing #{key}"
        end
      end
    end

    context 'with valid params' do
      let(:resume_url) { 'RESUME_URL' }

      before do
        allow(SecureRandom)
          .to receive(:uuid)
          .and_return(uuid)

        file_path = "#{@valid_params[:netid]}-#{uuid}"
        allow(AWS)
          .to receive(:upload_resume)
          .with(file_path, @valid_params[:resume])
          .and_return(true)

        allow(AWS)
          .to receive(:fetch_resume)
          .with(file_path)
          .and_return(resume_url)
      end

      it 'should create the student' do
        post '/students', @valid_params.to_json

        expect(last_response).to be_ok

        expect(Student.last.first_name).to eq @valid_params[:firstName]
        expect(Student.last.last_name).to eq @valid_params[:lastName]
        expect(Student.last.netid).to eq @valid_params[:netid]
      end

      it 'should upload the resume to S3' do
        file_path = "#{@valid_params[:netid]}-#{uuid}"
        expect(AWS)
          .to receive(:upload_resume)
          .with(file_path, @valid_params[:resume])
          .and_return(true)

        expect(AWS)
          .to receive(:fetch_resume)
          .with(file_path)
          .and_return(resume_url)

        post '/students', @valid_params.to_json
        expect(Student.last.resume_url).to eq resume_url
      end
    end
  end

  describe 'PUT /students/:netid/approve' do
    let!(:netid) { 'jsmith2' }
    let!(:student) {
      Student.create(
        first_name: 'John',
        last_name: 'Smith',
        netid: netid,
        email: "#{netid}@illinois.edu",
        graduation_date: Date.today.next_year,
        degree_type: 'Bachelors',
        job_type: 'Full-Time'
      )
    }

    it 'should approve a student whose resume has not already been approved' do
      expect(student.approved_resume).to eq false

      put "/students/#{netid}/approve", {}.to_json
      expect(last_response).to be_ok
      expect(Student.last.approved_resume).to eq true

      json_data = JSON.parse(last_response.body)
      expect(json_data['data'].count).to eq 0
    end

    it 'should not approve a student whose resume has already been approved' do
      student.update(approved_resume: true)

      put "/students/#{netid}/approve"

      expect(last_response).not_to be_ok
      json_data = JSON.parse(last_response.body)
      expect(json_data['error']).to eq 'Resume already approved'
    end

    it 'should return an error if it cannot find the student by netid' do
      put '/students/randomne/approve'

      expect(last_response).not_to be_ok
      json_data = JSON.parse(last_response.body)
      expect(json_data['error']).to eq 'Student not found'
    end
  end

  describe 'GET /students/:netid' do
    it 'should return the student by netid' do
      get "/students/#{netid}"

      expect(last_response).to be_ok

      json_data = JSON.parse(last_response.body)
      match_student(json_data['data'], student)
    end

    it 'should return an error if it cannot find the student by netid' do
      get "/students/#{netid}1"

      expect(last_response).not_to be_ok
    end
  end

  describe 'DELETE /students/:netid' do
    it 'should return an error if it cannot find the student by netid' do
      delete "/students/#{netid}1"

      expect(last_response).not_to be_ok
    end

    it 'should delete the student by netid' do
      delete "/students/#{netid}"

      expect(last_response).to be_ok
      expect(Student.last).to be_nil
    end

    it 'should remove their resume from S3' do
      expect(AWS)
        .to receive(:delete_resume)

      delete "/students/#{netid}"
      expect(last_response).to be_ok
    end

    it 'should return all other students with unapproved resumes' do
      delete "/students/#{netid}"

      expect(last_response).to be_ok
      json_data = JSON.parse(last_response.body)
      expect(json_data['data']).to eq []
    end
  end
end
