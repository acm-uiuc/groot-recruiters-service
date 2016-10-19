class Job
    include DataMapper::Resource

    property :id, Serial
    property :posted_on, DateTime
    property :title, String
    property :company, String
    property :contact_name, String
    property :contact_email, String
    property :contact_phone, String
    property :job_type, String
    property :description, String
    
end
