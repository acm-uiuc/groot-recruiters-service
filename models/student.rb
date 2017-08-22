# Copyright © 2017, ACM@UIUC
#
# This file is part of the Groot Project.
#
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.

require 'date'
require 'dm-validations'
require 'dm-timestamps'

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
  property :date_joined, Date, default: Date.today
  property :active, Boolean, default: true
  property :resume_url, Text
  property :approved_resume, Boolean, default: false
  property :created_on, Date
  property :updated_on, Date
  property :updated_at, DateTime

  def self.validate(params, attributes)
    attributes.each do |attr|
      return [400, "Missing #{attr}"] unless params[attr] && !params[attr].empty?
      case attr
      when :netid
        return [400, 'Invalid netid'] unless params[attr].length <= 8
      when :degreeType
        options = %w[Bachelors Masters Ph.D]
        return [400, "Valid options are: #{options}"] unless options.include? params[attr]
      when :jobType
        options = %w[Internship Full-Time Co-Op]
        return [400, "Valid options are: #{options}"] unless options.include? params[attr]
      end
    end

    [200, nil]
  end

  def serialize
    {
      first_name: first_name,
      last_name: last_name,
      netid: netid,
      email: email,
      graduation_date: graduation_date,
      degree_type: degree_type,
      job_type: job_type,
      active: active,
      date_joined: date_joined,
      resume_url: resume_url,
      approved_resume: approved_resume,
      created_on: created_on,
      updated_at: updated_at
    }
  end
end
