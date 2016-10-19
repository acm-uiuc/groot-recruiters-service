#Groot User Service

##Installing PostgreSQL
```sh
[package-manager] install postgres

initdb /usr/local/var/postgres
pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start
ps auxwww | grep postgres
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

```
[{"id":1,"posted_on":"2016-10-19T02:45:49-05:00","title":"Software Engineering Intern","company":"Apple","contact_name":"Steve Jobs","contact_email":"steve@apple.com","contact_phone":"11111111","job_type":"Full-time","description":"Free job"}]
```

###POST /jobs

`curl -X POST -d '{"job_title" => "Software Engineering Intern1", "org" => "Apple1", "contact-name" => "Steve Jobs", "contact-email" => "steve@apple.com", "contact-phone" => "11111111", "job-type" => "Full-time", "description" => "Free job"}' http://localhost:4567/jobs`

```
{"id":2,"posted_on":"2016-10-19T16:57:43+00:00","title":"Software Engineering Intern1","company":"Apple1","contact_name":"Steve Jobs","contact_email":"steve@apple.com","contact_phone":"11111111","job_type":"Full-time","description":"Free job"}
```

