# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
require 'net/http'
require 'uri'
require 'pry'

module Auth
  SERVICES_URL = 'http://localhost:8000'
  VERIFY_ADMIN_URL = '/groups/committees/admin?isMember='
  VALIDATE_SESSION_URL = '/session/'

  # Verifies that the request originates from Groot
  def self.verify_request(request)
    groot = Config.load_config("groot")
    groot_access_key = groot["request_key"]
    
    token = request['HTTP_AUTHORIZATION']

    "Basic #{groot_access_key}" == token
  end

  # Verifies that an admin (defined by groups service) originated this request
  def self.verify_admin(request)
    groot_access_key = Config.load_config("groot")["access_key"]
    netid = request['HTTP_NETID']
    
    uri = URI.parse("#{SERVICES_URL}#{VERIFY_ADMIN_URL}#{netid}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    request['Authorization'] = groot_access_key
    response = http.request(request)

    JSON.parse(response.body)["isValid"] == "true"
  end

  # Verifies that the session (validated by users service) is active
  def self.verify_session(request)
    session_token = request['HTTP_SESSION_TOKEN']
    groot_access_key = Config.load_config("groot")["access_key"]

    uri = URI.parse("#{SERVICES_URL}#{VALIDATE_SESSION_URL}#{session_token}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request['Authorization'] = groot_access_key
    response = http.request(request)

    JSON.parse(response.body)["isValid"] == "true"
  end

  def self.verify_active_session(request)
    self.verify_admin(request) && self.verify_session(request)
  end
end