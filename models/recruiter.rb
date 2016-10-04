#models/user

class Recruiter
    include DataMapper::Resource

    property :id, Serial
    property :first_name, String, required: true
    property :last_name, String, required: true
    property :netid, String, required: true, key: true, unique_index: true, length: 1...9
    property :date_joined, DateTime
    property :token, String
    property :admin, Boolean
    property :active, Boolean

    def self.is_valid_user?(first_name, last_name, netid ) #TODO: add password
        if first_name != nil && last_name != nil
            if netid.length <= 8
                return true
            else
                return false
            end
        else
            return false
        end
    end
end
