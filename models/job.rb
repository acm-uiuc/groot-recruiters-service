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
    property :posted_on, DateTime
    property :title, String
    property :company, String
    property :contact_name, String
    property :contact_email, String
    property :contact_phone, String
    property :job_type, String
    property :description, String
    property :status, String

    def self.is_valid?(params)
      params.each do |attr, val|
        return [400, "Missing #{attr}"] unless val
        case attr
        when :status
          return [400, "Invalid status"] unless ["Approve", "Defer"].include? val
      end
    end
end
