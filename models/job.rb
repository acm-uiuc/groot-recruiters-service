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

    def self.validate(params, attributes)
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

    def serialize
      {
        title: self.title,
        company: self.company,
        contact_name: self.contact_name,
        contact_email: self.contact_email,
        contact_phone: self.contact_phone,
        job_type: self.job_type,
        description: self.description,
        approved: self.approved
      }
    end
end
