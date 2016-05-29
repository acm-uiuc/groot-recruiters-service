source "https://rubygems.org"

gem 'bundler'
gem 'rake'

gem 'sinatra'
gem 'sinatra-contrib'
gem 'foreigner'

gem 'json'
gem 'data_mapper'
gem 'dm-migrations'
gem 'dm-core'
gem 'dm-timestamps'
gem 'dm-validations'
gem 'dm-noisy-failures', '~> 0.2.3'

group :production do
    gem 'dm-postgres-adapter', '~> 1.2'
    gem 'pg'

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
  gem 'shotgun' # Auto-reload sinatra app on change.
  gem 'better_errors' # Show an awesome console in the browser on error.
  gem 'rest-client'
  gem 'dm-sqlite-adapter'
  gem 'sqlite3', '~> 1.3', '>= 1.3.11'
end
