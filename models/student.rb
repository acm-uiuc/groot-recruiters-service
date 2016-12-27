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
    property :degree_type, String, required: true
    property :job_type, String, required: true
    property :netid, String, required: true, key: true, unique_index: true, length: 1...9
    property :date_joined, Date
    property :active, Boolean
    property :resume_url, Text
    property :approved_resume, Boolean

    def self.validate(params, attributes)
      attributes.each do |attr|
        return [400, "Missing #{attr}"] unless params[attr]
        case attr
        when :netid
          return [400, "Invalid netid"] unless params[attr].length <= 8
        when :degreeType
          options = ["Undergraduate", "Masters", "PhD"]
          return [400, "Valid options are: #{options.to_s}"] unless options.include? params[attr]
        when :jobType
          options = ["Internship", "Full-time", "Co-Op"]
          return [400, "Valid options are: #{options.to_s}"] unless options.include? params[attr]
        end
      end

      [200, nil]
    end

    def as_json
      self.to_json
    end
end
