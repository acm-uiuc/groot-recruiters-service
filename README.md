#Groot User Service

##Model
```ruby

class Recruiter
    include DataMapper::Resource

    property :id, Serial
    property :first_name, String, required: true
    property :last_name, String, required: true
    property :netid, String, required: true, key: true, unique_index: true, length: 1...8
    property :date_joined, DateTime
    property :token, String
    property :admin, Boolean
    property :active, Boolean

end
```

##Installing PostgreSQL
```sh
[package-manager] install postgres

initdb /usr/local/var/postgres
pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start
ps auxwww | grep postgres
createdb groot_recruiter_service
```
##Run Application
```sh
ruby app.rb
```

##Migrate DB after model alteration
```sh
rake db:migrate
```
