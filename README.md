#Groot User Service

##Installing MySQL
```sh
brew install mysql
```

In `mysql`:
```
CREATE DATABASE groot_recruiter_service
```

##Migrate DB after model alteration (clears all data)
```
rake db:migrate
```

## Create secrets.yaml

```
cp secrets.yaml.template secrets.yaml
```

Fill out username and password for email for ACM admin email.

##Run Application
```
ruby app.rb
```

##API Documentation

Note: All routes require an access token from groot (set in https://github.com/acm-uiuc/groot/blob/master/services/recruiters.go#L21) to be authenticated.

Some routes also require a recruiter to be logged in.

## Job Routes

###GET /jobs

Returns all deferred jobs in descending order.

```json
[{"id":1,"posted_on":"2016-10-19T02:45:49-05:00","title":"Software Engineering Intern","company":"Apple","contact_name":"Steve Jobs","contact_email":"steve@apple.com","contact_phone":"11111111","job_type":"Full-time","description":"Free job"}]
```

###POST /jobs

Creates a new job.

###PUT /jobs/status

###DELETE /jobs

## Recruiter Routes

###GET /recruiters/login

Validates recruiter credentials and stores them in the session.

###POST /recruiters/new

Creates a new recruiter and sends them an email with their credentials.

###POST /recruiters/logout

Logs recruiter out and clears session.

## Student Routes

###GET /students

Gets and filters students by their attributes.

###POST /students

Creates a new student and uploads their resume to S3. Anytime a student updates their resume, this endpoint will also be called.

###PUT /students/approve

Approves a student's resume.

###GET /student/:netid

Fetch a student's information by their netid.

###DELETE /student/:netid

Delete a student and their resume from S3.

## License

This project is licensed under the University of Illinois/NCSA Open Source License. For a full copy of this license take a look at the LICENSE file. 

When contributing new files to this project, preappend the following header to the file as a comment: 

```
Copyright © 2016, ACM@UIUC

This file is part of the Groot Project.  
 
The Groot Project is open source software, released under the University of Illinois/NCSA Open Source License. 
You should have received a copy of this license in a file with the distribution.
```
