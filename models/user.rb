#models/user

class User
    include DataMapper::Resource

    property :id, Serial
    property :first_name, String, required: true
    property :last_name, String, required: true
    property :email, String, required: true
    property :graduation_date, String, required: true
    property :degree_type, String, required: true
    property :job_type, String, required: true
    property :netid, String, required: true, key: true, unique_index: true, length: 1...9
    property :date_joined, DateTime
    property :token, String
    property :admin, Boolean
    property :active, Boolean
    property :approved_resume, Boolean

    def self.is_valid_user?(first_name, last_name, netid)
      return !first_name.nil? && !last_name.nil? && netid.length <= 8
    end
end
