# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
# app.rb

require 'json'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/cross_origin'
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
    register Sinatra::CrossOrigin
    
    configure do
      enable :cross_origin
    end

    set :raise_sinatra_param_exceptions, true

    error Sinatra::Param::InvalidParameterError do
        {error: "#{env['sinatra.error'].param} is invalid"}.to_json
    end

    db = Config.load_config("db")    
    configure :development do
        DataMapper::Logger.new($stdout, :debug)
        DataMapper.setup(
            :default,
            "mysql://" + db["user"] + ":" + db["password"] + "@" + db["hostname"]+ "/" + db["name"]
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
            "mysql://" + db["user"] + ":" + db["password"] + "@" + db["hostname"]+ "/" + db["name"]
      )
    end
    DataMapper.finalize
end
