# app.rb

require 'json'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'data_mapper'
require 'dm-migrations'
require "dm_noisy_failures"
require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'better_errors'
require 'dm-postgres-adapter'

set :root, File.dirname(__FILE__)
configure :development do
    DataMapper::Logger.new($stdout, :debug)
    DataMapper.setup(
        :default,
        'postgres://localhost/groot_users_service'
    )
    use BetterErrors::Middleware
    # you need to set the application root in order to abbreviate filenames
    # within the application:
    BetterErrors.application_root = File.expand_path('..', __FILE__)
    DataMapper.auto_upgrade!
end


configure :production do
    DataMapper.setup(
        :default,
        'postgres://localhost/groot_users_service'
    )
end

require_relative './models/init'
require_relative './routes/init'
require_relative './helpers/init'

DataMapper.finalize
