# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
source "https://rubygems.org"

gem 'bundler'
gem 'rake'

gem 'sinatra', '~> 1.4.7'
gem 'sinatra-contrib'
gem 'foreigner'
gem "sinatra-cross_origin", "~> 0.3.1"
gem 'json'
gem 'bcrypt'
gem 'data_mapper'
gem 'dm-migrations'
gem 'dm-core'
gem 'dm-timestamps'
gem 'dm-validations'
gem 'dm-noisy-failures', '~> 0.2.3'
gem 'aws-s3'
gem 'pony'
gem 'faker'

group :production do
  gem 'mysql'
  gem 'dm-mysql-adapter'
end

group :test do
  gem "codeclimate-test-reporter", require: nil
  gem 'rspec'
  gem 'rack-test'
  gem 'factory_girl'
  gem 'guard-rspec'
  gem 'faker'
  gem 'shoulda'
  gem 'database_cleaner'
  gem 'json_spec'
  gem 'webmock'
end

group :development, :test do
  gem 'pry'
  gem 'rb-readline'
  gem 'pry-coolline'
  gem 'shotgun' # Auto-reload sinatra app on change.
  gem 'better_errors' # Show an awesome console in the browser on error.
  gem 'rest-client'
  gem 'dm-sqlite-adapter'
  gem 'sqlite3', '~> 1.3', '>= 1.3.11'
end
