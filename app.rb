# Copyright © 2017, ACM@UIUC
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
require 'dm-mysql-adapter'
require 'better_errors'
require 'json'
require 'jwt'

require_relative 'helpers/init'
require_relative 'routes/init'
require_relative 'models/init'

class GrootRecruiterService < Sinatra::Base
    register Sinatra::AuthsRoutes
    register Sinatra::JobsRoutes
    register Sinatra::RecruitersRoutes
    register Sinatra::StudentsRoutes
    register Sinatra::CrossOrigin
    
    configure do
      enable :cross_origin
      enable :logging
    end

    configure :development do
        db = Config.load_db("development")    
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

    configure :test do
        db = Config.load_db("test")
        DataMapper.setup(
            :default,
            "mysql://" + db["user"] + ":" + db["password"] + "@" + db["hostname"]+ "/" + db["name"]
        )
        DataMapper.auto_upgrade!
    end

    configure :production do
        db = Config.load_db("production")
        DataMapper.setup(
            :default,
            "mysql://" + db["user"] + ":" + db["password"] + "@" + db["hostname"]+ "/" + db["name"]
        )
    end

    DataMapper.finalize
end
