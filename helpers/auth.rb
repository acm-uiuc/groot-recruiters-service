# Copyright © 2017, ACM@UIUC
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
  VERIFY_CORPORATE_URL = '/groups/committees/corporate?isMember='
  VALIDATE_SESSION_URL = '/session/'

  # Verifies that the request originates from Groot
  def self.verify_request(request)
    groot = Config.load_config("groot")
    groot_access_key = groot["request_key"]
    
    token = request['HTTP_AUTHORIZATION']

    "#{groot_access_key}" == token
  end

  # Verifies that an admin (defined by groups service) originated this request
  def self.verify_corporate(request)
    groot_access_key = Config.load_config("groot")["access_key"]
    netid = request['HTTP_NETID']
    
    uri = URI.parse("#{SERVICES_URL}#{VERIFY_CORPORATE_URL}#{netid}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    request['Authorization'] = groot_access_key
    
    response = http.request(request)
    return false unless response.code == "200"
    JSON.parse(response.body)["isValid"]
  end

  # Verifies that the session (validated by users service) is active
  def self.verify_session(request)
    session_token = request['HTTP_TOKEN']
    groot_access_key = Config.load_config("groot")["access_key"]
    
    uri = URI.parse("#{SERVICES_URL}#{VALIDATE_SESSION_URL}#{session_token}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = {
      validationFactors: [{
        value: '127.0.0.1',
        name: 'remote_address'
      }]
    }.to_json
    request['Authorization'] = groot_access_key
    request['Accept'] = 'application/json'
    request['Content-Type'] = 'application/json'
    response = http.request(request)
    
    return false unless response.code == "200"
    JSON.parse(response.body)["token"] == session_token
  end

  def self.verify_corporate_session(request)
    self.verify_session(request) && self.verify_corporate(request)
  end
end