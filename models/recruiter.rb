require 'dm-validations'
require 'dm-core'

APP_SECRET = "my special secret"

class Recruiter
    include DataMapper::Resource
    
    property :id, Serial
    property :encrypted_password, Text
    property :email, String
    property :company_name, String
    property :first_name, String
    property :last_name, String
    property :type, String
    
    def check_password(password)
      return false
    end
end