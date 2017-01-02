# Groot Recruiter Service

- The recruiter service serves as an API portal for recruiters to view resumes uploaded by students and interact with job ads.

## Installing MySQL
```sh
brew install mysql
```

## Migrate DB after model alteration (clears all data)
```
rake db:migrate
```

## Create secrets.yaml and database.yaml

```
cp secrets.yaml.template secrets.yaml
cp database.yaml.template database.yaml
```

Fill out the appropriate credentials in each of the yaml files. For example, fill in the correct email and password.

## Create databases

You need to login to `mysql`, and create the database names for your development and test environments and fill it in the `database.yaml`. For example,

In `mysql`:
```
CREATE DATABASE groot_recruiter_service
```

## Run Application
```
ruby app.rb
```

## API Documentation

Note: All routes require an access token from groot (set in https://github.com/acm-uiuc/groot/blob/master/services/recruiters.go#L21) to be authenticated. This access token will be validated in `config/secrets.yaml` under the `access_token` key.

Some routes also require a recruiter to be logged in. This will be managed by the session.

You can view routes by running `rake routes:show`. The shortened output will be printed first, followed by a description of each route.

```
:: GET ::
/jobs
/recruiters
/status
/students
/students/:netid

:: HEAD ::
/jobs
/recruiters
/status
/students
/students/:netid

:: OPTIONS ::
:splat

:: POST ::
/jobs
/recruiters
/recruiters/:recruiter_id/reset_password
/recruiters/login
/students

:: PUT ::
/jobs/:job_id/approve
/recruiters/:recruiter_id
/students/:netid/approve

:: DELETE ::
/jobs/:job_id
/students/:netid
```

---

## Job Routes

### GET /jobs

Returns all deferred (unapproved) jobs in descending order.

**Required Params**
- None

### POST /jobs

Creates a new job ad.

**Required Params**
- [:job_title, :organization, :contact_name, :contact_email, :contact_phone, :job_type, :description]

### PUT /jobs/:job_id/approve

Approve a job ad. *Requires admin privileges*.

**Required Params**
- [:job_id]

### DELETE /jobs/:job_id

Delete a job ad. *Requires admin privileges*.

**Required Params**
- [:job_id]

---

## Recruiter Routes

### POST /recruiters/login

Verifies recruiter credentials if login was successful.

**Required Params**
- [:email, :password]

### POST /recruiters

Creates a new recruiter and sends them an email with their credentials.

**Required Params**
- [:company_name, :first_name, :last_name, :email]

### GET /recruiters/:recruiter_id/reset_password

Resets a recruiter's password and sends them another one via email.

**Required Params**
- Required params[:email]

### PUT /recruiters/:recruiter_id/

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

### PUT /students/:netid/approve

Approves a student's resume.

**Required Params**
- [:netid]

### GET /students/:netid

Fetch a student's information by their netid.

**Required Params**
- [:netid]

### DELETE /students/:netid

Delete a student from the database and their resume from S3.

**Required Params**
- [:netid]

---

## Running Tests

- Every model, route, and helper *should* have an associated spec file.

Run tests with `rake spec`.

## License

This project is licensed under the University of Illinois/NCSA Open Source License. For a full copy of this license take a look at the LICENSE file. 

When contributing new files to this project, preappend the following header to the file as a comment: 

```
Copyright © 2016, ACM@UIUC

This file is part of the Groot Project.  
 
The Groot Project is open source software, released under the University of Illinois/NCSA Open Source License. 
You should have received a copy of this license in a file with the distribution.
```
