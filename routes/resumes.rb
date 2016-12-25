# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
# encoding: UTF-8
require 'pry'

module Sinatra
    module ResumesRoutes
        def self.registered(app)
            app.get '/resumes/unapproved' do
              # TODO switch to /users
              
              ResponseFormat.format_response(result, request.accept)
            end
          
            
            # app.delete '/resumes' do
            #   params = JSON.parse(request.body.read)
            #   param :netid,             String, required: true

            #   return [400, "Missing netid"] unless params[:netid]
              
            #   successful_delete = AWS.delete_resume(params[:netid])
            #   return [400, "Error deleting resume with netid #{params[:netid]} to S3"] unless successful_delete
              
            #   200
            # end
        end
    end
    register ResumesRoutes
end
