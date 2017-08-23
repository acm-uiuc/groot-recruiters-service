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
      app.set port: 4567
      app.set bind: '0.0.0.0'

      app.get '/status' do
        ResponseFormat.message('OK')
      end

      # Handle CORS prefetching
      app.options '*' do
        response.headers['Allow'] = 'HEAD,GET,PUT,POST,DELETE,OPTIONS'
        response.headers['Access-Control-Allow-Headers'] =
          'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, '\
          'Accept, Origin, Access-Control-Allow-Origin'
        response.headers['Access-Control-Allow-Origin'] = '*'
        200
      end
    end
  end
  register AuthsRoutes
end
