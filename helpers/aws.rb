# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
require 'aws/s3'
require 'base64'
require 'pry'

module AWS
    BUCKET = 'storage.acm.illinois.edu'
    RESUME_S3_LOCATION = "#{BUCKET}/resumes"
    
    def self.init_aws()
      aws = Config.load_config("aws")
      AWS::S3::Base.establish_connection!(
        access_key_id: aws["access_key_id"],
        secret_access_key: aws["secret_access_key"]
      )
    end

    def self.upload_file(file_path, file_key)
        self.init_aws
        
        # Store if not already stored
        AWS::S3::S3Object.store(file_key + ".pdf", open(file_path), RESUME_S3_LOCATION) if self.fetch_resume(file_key) == false
    end
    
    def self.upload_resume(file_key, data)
        return if data.nil?
        self.init_aws
        
        buffer = JSONBase64Decoder.decode(data)
        
        AWS::S3::S3Object.store(file_key + ".pdf", Base64.decode64(buffer["data"]), RESUME_S3_LOCATION, content_type: 'application/pdf')
    end
    
    def self.fetch_resume(file_key)
        self.init_aws
        
        return false unless AWS::S3::S3Object.exists?(file_key + ".pdf", RESUME_S3_LOCATION)
        
        resume = AWS::S3::S3Object.find("resumes/#{file_key}.pdf", BUCKET)

        resume.url(expires_in: 60 * 60 * 24 * 365 * 4) # expires in 4 years
    end
    
    def self.delete_resume(netid, resume_url)
        self.init_aws
        
        file_name = resume_url[resume_url.index(netid)..-resume_url.index(".pdf") + ".pdf".length]
        return false unless AWS::S3::S3Object.exists?(file_name, RESUME_S3_LOCATION)
        
        AWS::S3::S3Object.delete(file_name, RESUME_S3_LOCATION)
    end
end
