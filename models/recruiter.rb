require 'dm-validations'

class Recruiter
    include DataMapper::Resource
    
    property :id, Serial
    property :password, String # TODO add encryption
    property :email, String
    attr_accessor :password_confirmation
    validates_confirmation_of :password
end