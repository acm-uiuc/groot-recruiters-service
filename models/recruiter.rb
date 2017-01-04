# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
require 'date'
require 'dm-validations'
require 'dm-timestamps'

class Recruiter
    include DataMapper::Resource
    
    property :id, Serial
    property :encrypted_password, Text, required: true
    property :expires_on, Date, default: Date.today.next_year
    property :email, String, required: true, unique: true
    property :company_name, String, required: true
    property :first_name, String, required: true
    property :last_name, String, required: true

    property :created_on, Date
    property :updated_on, Date

    def self.validate(params, attributes)
      attributes.each do |attr|
        return [400, "Missing #{attr}"] unless params[attr] && !params[attr].empty?
      end

      [200, nil]
    end

    def serialize
      {
        id: self.id,
        expires_on: self.expires_on,
        email: self.email,
        company_name: self.company_name,
        first_name: self.first_name,
        last_name: self.last_name,
        created_on: self.created_on,
        updated_on: self.updated_on
      }
    end
end