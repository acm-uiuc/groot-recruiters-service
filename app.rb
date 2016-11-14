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
require 'dm-mysql-adapter'
require_relative 'helpers/init'
require_relative 'routes/init'
require_relative 'models/init'

class GrootRecruiterService < Sinatra::Base

    enable :sessions

    helpers ResponseFormat
    helpers Config
    helpers JSONBase64Decoder

    register Sinatra::ResumesRoutes
    register Sinatra::UsersRoutes

    configure :development do
        DataMapper::Logger.new($stdout, :debug)
        DataMapper.setup(
            :default,
            'mysql://localhost/groot_recruiter_service'
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
            'mysql://localhost/groot_recruiter_service'
        )
    end
    DataMapper.finalize
end
