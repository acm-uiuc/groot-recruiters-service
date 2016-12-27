# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
class Job
    include DataMapper::Resource

    property :id, Serial
    property :posted_on, Date, required: true
    property :title, String, required: true
    property :company, String, required: true
    property :contact_name, String, required: true
    property :contact_email, String, required: true
    property :contact_phone, String, required: true
    property :job_type, String
    property :description, String, required: true
    property :approved, Boolean

    def self.validate!(params, attributes)
      attributes.each do |attr|
        return [400, "Missing #{attr}"] unless params[attr]
        case attr
        when :job_type
          options = ["Full-Time", "Part-Time", "Intern"]
          return [400, "Valid options are: #{options.to_s}"] unless options.include? params[attr]
        end
      end

      [200, nil]
    end
end
