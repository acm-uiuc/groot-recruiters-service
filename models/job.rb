class Job
    include DataMapper::Resource

    property :id, Serial
    property :posted_on, DateTime
    property :company, String
    property :contact_name, String
    property :contact_email, String
    property :contact_phone, String
    property :type_full, Boolean
    property :type_parttime, Boolean
    property :type_intern, Boolean
    property :description, String
    
end
