# Copyright © 2017, ACM@UIUC
#
# This file is part of the Groot Project.
#
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
# app.rb

require 'dm_noisy_failures'
require 'better_errors'
require 'data_mapper'
require 'dm-core'
require 'dm-migrations'
require 'dm-mysql-adapter'
require 'dm-timestamps'
require 'dm-validations'
require 'json'
require 'json'
require 'jwt'
require 'sinatra'
require 'sinatra/cross_origin'
require 'sinatra/reloader' if development?

require_relative './helpers/init'
require_relative './models/init'
require_relative './routes/init'

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

  configure :development, :production do
    db = Config.load_config('database')
    DataMapper.setup(:default, 'mysql://' + db['user'] + ':' + db['password'] + '@' + db['hostname'] + '/' + db['name'])
  end

  configure :test do
    db = Config.load_config('test_database')
    DataMapper.setup(:default, 'mysql://' + db['user'] + ':' + db['password'] + '@' + db['hostname'] + '/' + db['name'])
  end

  configure :development do
    enable :unsecure
    register Sinatra::Reloader

    DataMapper::Logger.new($stdout, :debug)
    use BetterErrors::Middleware

    BetterErrors.application_root = File.expand_path('..', __FILE__)
    DataMapper.auto_upgrade!
  end

  configure :production do
    disable :unsecure
  end

  DataMapper.finalize
end
