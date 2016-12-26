# Copyright © 2016, ACM@UIUC
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
        halt(400) unless Auth.verify_token(env)
      end

      app.get '/status' do
        return [200, "OK"]
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