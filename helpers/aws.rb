# Copyright © 2017, ACM@UIUC
#
# This file is part of the Groot Project.
#
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.

require 'aws/s3'
require 'base64'

module AWS
  BUCKET = 'storage.acm.illinois.edu'.freeze
  RESUME_S3_LOCATION = "#{BUCKET}/resumes".freeze

  def self.init_aws
    aws = Config.load_config('aws')
    AWS::S3::Base.establish_connection!(
      access_key_id: aws['access_key_id'],
      secret_access_key: aws['secret_access_key']
    )
  end

  def self.upload_file(file_path, file_key)
    init_aws

    # Store if not already stored
    AWS::S3::S3Object.store(file_key + '.pdf', open(file_path), RESUME_S3_LOCATION) if fetch_resume(file_key) == false
  end

  def self.upload_resume(file_key, data)
    return if data.nil?
    init_aws

    buffer = JSONBase64Decoder.decode(data)

    AWS::S3::S3Object.store(file_key + '.pdf', Base64.decode64(buffer['data']),
                            RESUME_S3_LOCATION, content_type: 'application/pdf')
  end

  def self.fetch_resume(file_key)
    init_aws

    return false unless AWS::S3::S3Object.exists?(file_key + '.pdf', RESUME_S3_LOCATION)

    AWS::S3::S3Object.find("resumes/#{file_key}.pdf", BUCKET)
    "http://#{RESUME_S3_LOCATION}/#{file_key}.pdf"
  end

  def self.delete_resume(netid, resume_url)
    init_aws

    return false unless resume_url

    netid_in_file = resume_url.index(netid)
    return false unless netid_in_file

    # add 4 for length of .pdf
    file_name = resume_url[netid_in_file..resume_url.index('.pdf') + 4]
    return false unless AWS::S3::S3Object.exists?(file_name, RESUME_S3_LOCATION)

    AWS::S3::S3Object.delete(file_name, RESUME_S3_LOCATION)
  end
end
