# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
module Auth
  SERVICES_URL = 'http://localhost:8000'

  def self.verify_admin(request)
    user_id = request.env["GROOT_USER_ID"]
  end

  def self.verify_token(request)
    groot = Config.load_config("groot")
    expected_token = groot['access_key']

    actual_token = request["HTTP_AUTHORIZATION"]

    "Basic #{expected_token}" == actual_token
  end
end