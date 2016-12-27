# Groot Recruiter Service

- The recruiter service serves as an API portal for recruiters to view resumes uploaded by students and interact with job ads.

## Installing MySQL
```sh
brew install mysql
```

In `mysql`:
```
CREATE DATABASE groot_recruiter_service
```

## Migrate DB after model alteration (clears all data)
```
rake db:migrate
```

## Create secrets.yaml

```
cp secrets.yaml.template secrets.yaml
```

Fill out username and password for email for ACM admin email.

## Run Application
```
ruby app.rb
```

## API Documentation

Note: All routes require an access token from groot (set in https://github.com/acm-uiuc/groot/blob/master/services/recruiters.go#L21) to be authenticated. This access token will be validated in `config/secrets.yaml` under the `access_token` key.

Some routes also require a recruiter to be logged in. This will be managed by the session.

---

## Job Routes

### GET /jobs

Returns all deferred jobs in descending order.

**Required Params**
- None

### POST /jobs

Creates a new job ad.

**Required Params**
- [:job_title, :organization, :contact_name, :contact_email, :contact_phone, :job_type, :description, :expires_at]

### PUT /jobs/status

**Required Params**
- [:job_title, :organization, :status]

### DELETE /jobs

**Required Params**
- [:job_title, :organization]

---

## Recruiter Routes

### GET /recruiters/login

Verifies recruiter credentials and stores recruiter id in the session if login was successful.

**Required Params**
- [:email, :password]

### POST /recruiters/new

Creates a new recruiter and sends them an email with their credentials.

**Required Params**
- [:company_name, :first_name, :last_name, :email, :type]

### POST /recruiters/logout

Logs recruiter out and clears session.

**Required Params**
- None

### GET /recruiters/reset_password

Resets a recruiter's password and sends them another one via email.

**Required Params**
- Required params[:email]

### PUT /recruiters

Updates a recruiter's password

**Required Params**
- [:email, :password, :new_password]

---

## Student Routes

### GET /students

Gets and filters students by their attributes.

**Optional Params**
- [:graduationStart, :graduationEnd, :netid, :degree_type, :job_type, :approved_resumes]

### POST /students

Creates a new student and uploads their resume to S3. Anytime a student updates their resume, this endpoint will also be called.

**Required Params**
- [:netid, :firstName, :lastName, :email, :gradYear, :degreeType, :jobType, :resume]

### PUT /students/approve

Approves a student's resume.

**Required Params**
- [:netid]

### GET /student/:netid

Fetch a student's information by their netid.

**Required Params**
- [:netid]

### DELETE /student/:netid

Delete a student from the database and their resume from S3.

**Required Params**
- [:netid]

---

## License

This project is licensed under the University of Illinois/NCSA Open Source License. For a full copy of this license take a look at the LICENSE file. 

When contributing new files to this project, preappend the following header to the file as a comment: 

```
Copyright © 2016, ACM@UIUC

This file is part of the Groot Project.  
 
The Groot Project is open source software, released under the University of Illinois/NCSA Open Source License. 
You should have received a copy of this license in a file with the distribution.
```
