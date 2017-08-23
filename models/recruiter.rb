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

class Recruiter
  include DataMapper::Resource

  property :id, Serial
  property :encrypted_password, BCryptHash
  property :expires_on, Date, default: Date.today.next_year
  property :email, String, required: true, unique: true
  property :company_name, String, required: true
  property :first_name, String, required: true
  property :last_name, String, required: true
  property :type, String, required: true
  property :invited, Boolean, default: false
  property :created_on, Date
  property :updated_on, Date

  def self.validate(params, attributes)
    attributes.each do |attr|
      return [400, "Missing #{attr}"] unless params[attr] && !params[attr].empty?

      case attr
      when :type
        options = %w[Sponsor Jobfair Startup Outreach]
        return [400, "Valid options are: #{options}"] unless options.include? params[attr]
      end
    end

    [200, nil]
  end

  def serialize
    {
      id: id,
      expires_on: expires_on,
      email: email,
      company_name: company_name,
      first_name: first_name,
      last_name: last_name,
      created_on: created_on,
      updated_on: updated_on,
      type: type,
      invited: invited,
      is_sponsor: sponsor?
    }
  end

  def sponsor?
    type == 'Sponsor'
  end
end
