require 'faker'
require_relative '../models/init'
require_relative '../helpers/init'
require 'pry'

BASE_64_PDF_STRING = File.read(Dir.pwd + "/scripts/sample.txt")

50.times do
  Student.create!(
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    netid: Faker::Internet.user_name(6..7),
    email: Faker::Internet.email,
    graduation_date: ["May 2019", "December 2019", "May 2018", "December 2018"].sample,
    degree_type: ["Bachelors", "Masters", "Ph.D"].sample,
    job_type: ["Internship", "Full-Time", "Co-Op"].sample,
    date_joined: Faker::Date.backward(90),
    active: true,
    resume_url: Faker::Internet.url,
    approved_resume: false,
  )


  Recruiter.create!(
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    company_name: Faker::Company.name,
    email: Faker::Internet.email,
    encrypted_password: Encrypt.encrypt_password(Faker::Internet.password(8)),
    expires_on: Faker::Date.forward(23)
  )

  Job.create!(
    title: Faker::Name.title,
    company: Faker::Company.name,
    contact_name: Faker::Name.name,
    contact_email: Faker::Internet.email,
    contact_phone: Faker::PhoneNumber.cell_phone,
    job_type: ["Internship", "Full-Time", "Co-Op"].sample,
    posted_on: Faker::Date.backward(90),
    description: Faker::Lorem.paragraph,
    approved: false,
  )
end