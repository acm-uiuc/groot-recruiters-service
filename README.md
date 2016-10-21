#Groot User Service

##Installing PostgreSQL
```sh
brew install postgres
createdb groot_recruiter_service
```
##Run Application
```
ruby app.rb
```

##Migrate DB after model alteration (clears all data)
```
rake db:migrate
```

##API Documentation

###GET /jobs

`curl -X GET http://localhost:4567/jobs`

```json
[{"id":1,"posted_on":"2016-10-19T02:45:49-05:00","title":"Software Engineering Intern","company":"Apple","contact_name":"Steve Jobs","contact_email":"steve@apple.com","contact_phone":"11111111","job_type":"Full-time","description":"Free job"}]
```

###POST /jobs

`curl -X POST -d '{"job_title" => "Software Engineering Intern1", "org" => "Apple1", "contact-name" => "Steve Jobs", "contact-email" => "steve@apple.com", "contact-phone" => "11111111", "job-type" => "Full-time", "description" => "Free job"}' http://localhost:4567/jobs`

```json
{"id":2,"posted_on":"2016-10-19T16:57:43+00:00","title":"Software Engineering Intern1","company":"Apple1","contact_name":"Steve Jobs","contact_email":"steve@apple.com","contact_phone":"11111111","job_type":"Full-time","description":"Free job"}
```

###PUT /jobs/status

`curl -X PUT -d '{"job_title" => "SWE", "org" => "Apple", "status" => "Defer/Approve/Reject"} http://localhost:4567/jobs/status`

```json
OK
```

###DELETE /jobs

`curl -X DELETE -d '{"job_title" => "SWE", "org" => "Apple"}' http://localhost:4567/jobs`

```json
OK
```

###GET /recruiters/login

`curl -X GET -d '{"email"=>"sample@illinois.edu", "password"=>"wzthknbu"}' http://localhost:4567/recruiters/login`

```json
OK
```

###POST /recruiters/new

`curl -X POST -d '{"company_name"=>"Apple", "first_name" => "Steve", "last_name" => "Jobs", "email"=>"banana@apple.com", "type" => "Jobfair Company"}' http://localhost:4567/recruiters/new`

```json
Created recruiter
```

###GET /resumes/unapproved

`curl -X GET http://localhost:4567/resumes/unapproved`

```json
[
  {
    "firstName": "Sameet",
    "lastName": "Sapra",
    "netid": "ssapra2",
    "dateJoined": "2016-10-20T01:30:03-05:00",
    "resume": "AMAZON S3 URL"
  }
]
```

###POST /resumes

`curl -X POST -d '{"firstName"=>"Sameet", "lastName"=>"Sapra", "netid"=>"ssapra2", "email"=>"ssapra2@illinois.edu", "gradYear"=>"May 2018", "degreeType"=>"Bachelors", "jobType"=>"Co-Op", "resume"=>"Base 64 PDF String"}' http://localhost:4567/resumes/`

```json
{"id":1,"first_name":"Sameet","last_name":"Sapra","email":"ssapra2@illinois.edu","graduation_date":"2016-05-01T00:00:00+00:00","degree_type":"Bachelors","job_type":"Internship","netid":"ssapra2","date_joined":"2016-10-20T01:30:03+00:00","token":null,"admin":null,"active":null,"approved_resume":false}
```

###PUT /resumes/approve

`curl -X PUT -d '{"netid"=>"ssapra2"}' http://localhost:4567/resumes/approve`

```json
OK
```

###DELETE /resumes

`curl -X DELETE -d '{"netid"=>"ssapra2"}' http://localhost:4567/resumes/`

```json
OK
```

###GET /users/
###GET /users/:netid
###PUT /users/:netid
###DELETE /users/:netid

###GET /users/search

`curl -X GET -d '{"graduation_start" => "2017-05-01"}' http://localhost:4567/users/search`
`curl -X GET -d '{"job_type" => "Internship"}' http://localhost:4567/users/search`