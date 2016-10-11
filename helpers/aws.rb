require 'aws/s3'
require 'base64'
require 'pry'

module AWS
    BUCKET = 'groot-recruiters-service-fs'
    RESUME_S3_LOCATION = "#{BUCKET}/resumes"
    def self.init_aws()
      aws = Config.load_config("aws")
      AWS::S3::Base.establish_connection!(
        access_key_id: aws["access_key_id"],
        secret_access_key: aws["secret_access_key"]
      )
    end
    
    def self.upload_resume(netid, data)
        return if data.nil?
        self.init_aws
        
        buffer = JSONBase64Decoder.decode(data)
        AWS::S3::S3Object.store(netid + ".pdf", Base64.decode64(buffer["data"]), RESUME_S3_LOCATION, content_type: 'application/pdf')
    end
    
    def self.fetch_resume(netid)
        self.init_aws
        
        return false unless AWS::S3::S3Object.exists?(netid + ".pdf", RESUME_S3_LOCATION)
        
        resume = AWS::S3::S3Object.find("resumes/#{netid}.pdf", BUCKET)
        return resume.url
    end
    
    def self.delete_resume(netid)
        self.init_aws
        
        return false unless AWS::S3::S3Object.exists?(netid + ".pdf", RESUME_S3_LOCATION)
        
        AWS::S3::S3Object.delete(netid + ".pdf", RESUME_S3_LOCATION)
    end
end
