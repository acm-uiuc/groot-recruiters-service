# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
require 'net/http'
require 'uri'

module Auth
  SERVICES_URL = 'http://localhost:8000'
  VERIFY_ADMIN_URL = '/groups/committees/admin?isMember='

  def self.verify_admin(request)
    netid = request['HTTP_NETID']

    uri = URI.parse("#{SERVICES_URL}#{VERIFY_ADMIN_URL}#{netid}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    JSON.parse(response.body)["isValid"] == "true"
  end

  def self.verify_token(request)
    groot = Config.load_config("groot")
    expected_token = groot['access_key']

    actual_token = request["HTTP_AUTHORIZATION"]

    "Basic #{expected_token}" == actual_token
  end
end