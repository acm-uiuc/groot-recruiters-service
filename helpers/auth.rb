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
  VERIFY_CORPORATE_URL = '/groups/committees/corporate?isMember='
  VALIDATE_SESSION_URL = '/session/'

  def self.services_url
    Config.load_config("groot")["host"]
  end

  def self.groot_access_key
    Config.load_config("groot")["access_key"]
  end

  # Verifies that an admin (defined by groups service) originated this request
  def self.verify_credentials(type, request)
    netid = request['HTTP_NETID']
    
    uri = URI.parse("#{Auth.services_url}#{VERIFY_COMMITTEE_URL}#{type}?isMember=#{netid}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    request['Authorization'] = Auth.groot_access_key
    
    response = http.request(request)
    return response.code == "200"
  end

  # Verifies that the session (validated by users service) is active
  def self.verify_session(request)
    session_token = request['HTTP_TOKEN']
    
    uri = URI.parse("#{Auth.services_url}#{VALIDATE_SESSION_URL}#{session_token}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = {
      validationFactors: [{
        value: '127.0.0.1',
        name: 'remote_address'
      }]
    }.to_json
    request['Authorization'] = self.groot_access_key
    request['Accept'] = 'application/json'
    request['Content-Type'] = 'application/json'
    response = http.request(request)
    
    return false unless response.code == "200"
    JSON.parse(response.body)["token"] == session_token
  end

  def self.verify_admin_session(request)
    self.verify_session(request) && (
      self.verify_credentials('admin', request) ||
      self.verify_credentials('top4', request) ||
      self.verify_credentials('corporate', request)
    )
  end
end