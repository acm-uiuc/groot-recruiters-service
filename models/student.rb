# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
#models/user

class Student
    include DataMapper::Resource

    property :id, Serial
    property :first_name, String, required: true
    property :last_name, String, required: true
    property :email, String, required: true
    property :graduation_date, Date, required: true
    property :program, String, required: true
    property :job_type, String, required: true
    property :netid, String, required: true, key: true, unique_index: true, length: 1...9
    property :date_joined, Date
    property :active, Boolean
    property :approved_resume, Boolean

    def self.is_valid?(first_name, last_name, netid)
      return !first_name.nil? && !last_name.nil? && netid.length <= 8
    end
end
