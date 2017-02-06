# Copyright © 2017, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
# encoding: UTF-8
module Sinatra
  module AuthsRoutes
    def self.registered(app)
      app.before do
        halt(401, Errors::VERIFY_GROOT) unless Auth.verify_request(env) || settings.unsecure
      end

      app.get '/status' do
        ResponseFormat.message("OK")
      end

      app.get '/status/corporate' do
        halt(403, Errors::VERIFY_CORPORATE_SESSION) unless Auth.verify_corporate(env)
        ResponseFormat.message("OK")
      end

      app.get '/status/session' do
        halt(403, Errors::VERIFY_CORPORATE_SESSION) unless Auth.verify_session(env)
        ResponseFormat.message("OK")
      end

      # Handle CORS prefetching
      app.options "*" do
        response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept, Origin, Access-Control-Allow-Origin"
        response.headers["Access-Control-Allow-Origin"] = "*"
        200
      end
    end
  end
  register AuthsRoutes
end