require 'faker'
require_relative '../models/init'
require_relative '../helpers/init'

50.times do
  Student.create(
    first_name: Faker::Name.unique.first_name,
    last_name: Faker::Name.unique.last_name,
    netid: Faker::Internet.unique.user_name(6..7),
    email: Faker::Internet.unique.email,
    graduation_date: ["May 2019", "December 2019", "May 2018", "December 2018"].sample,
    degree_type: ["Bachelors", "Masters", "Ph.D"].sample,
    job_type: ["Internship", "Full-Time", "Co-Op"].sample,
    date_joined: Faker::Date.backward(90),
    active: true,
    resume_url: Faker::Internet.url,
    approved_resume: false,
  )

  Recruiter.create(
    first_name: Faker::Name.unique.first_name,
    last_name: Faker::Name.unique.last_name,
    company_name: Faker::Company.unique.name,
    email: Faker::Internet.unique.email,
    encrypted_password: Encrypt.encrypt_password(Faker::Internet.password(8)),
    expires_on: Faker::Date.forward(23)
  )

  Job.create(
    title: Faker::Name.unique.title,
    company: Faker::Company.unique.name,
    contact_name: Faker::Name.unique.name,
    contact_email: Faker::Internet.unique.email,
    contact_phone: Faker::PhoneNumber.unique.cell_phone,
    job_type: ["Internship", "Full-Time", "Co-Op"].sample,
    description: Faker::Lorem.paragraph,
    approved: false,
  )
end