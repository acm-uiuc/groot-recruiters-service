# Copyright © 2017, ACM@UIUC
#
# This file is part of the Groot Project.
#
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
source 'https://rubygems.org'

gem 'aws-s3'
gem 'bcrypt'
gem 'bundler'
gem 'data_mapper'
gem 'dm-core'
gem 'dm-migrations'
gem 'dm-noisy-failures', '~> 0.2.3'
gem 'dm-timestamps'
gem 'dm-validations'
gem 'foreigner'
gem 'json'
gem 'jwt'
gem 'pony'
gem 'rake'
gem 'sinatra', '~> 1.4.7'
gem 'sinatra-contrib'
gem 'sinatra-cross_origin', '~> 0.3.1'

group :production do
  gem 'dm-mysql-adapter'
  gem 'mysql'
end

group :test do
  gem 'codeclimate-test-reporter', require: nil
  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'faker'
  gem 'guard-rspec'
  gem 'json_spec'
  gem 'rack-test'
  gem 'rspec'
  gem 'shoulda'
  gem 'webmock'
end

group :development, :test do
  gem 'better_errors' # Show an awesome console in the browser on error.
  gem 'pry'
  gem 'pry-coolline'
  gem 'rb-readline'
  gem 'rest-client'
  gem 'shotgun' # Auto-reload sinatra app on change.
end
