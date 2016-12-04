# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
require 'dm-validations'

class Recruiter
    include DataMapper::Resource
    
    property :id, Serial
    property :encrypted_password, Text
    property :expires_at, DateTime
    property :email, String
    property :company_name, String
    property :first_name, String
    property :last_name, String
    property :type, String
end