require 'pry'
require_relative '../helpers/aws'

def get_student(row)
  s = Student.new
  s.first_name = row['first_name']
  s.last_name = row['last_name']
  s.netid = row['netid']
  s.email = "#{s.netid}@illinois.edu"
  s.date_joined = Date.strptime(row['created_at'].split(" ")[0], '%m/%d/%y')
  s.graduation_date = Date.strptime(row['graduation'], '%m/%d/%y')
  
  s.degree_type = case row['level']
      when 'u'
        'Bachelors'
      when 'm'
        'Masters'
      when 'p'
        'Ph.D'
      end
  
  s.job_type = case row['seeking']
      when 'f'
          'Full-Time'
      when 'i'
          'Internship'
      when 'c'
          'Co-Op'
      end

  s.active = true
  s
end

STUDENT_FILE_PATH = "/scripts/2017-01-04.csv"
puts "IMPORT LOCATION: #{STUDENT_FILE_PATH}"

CSV.foreach(Dir.pwd + STUDENT_FILE_PATH, headers: true) do |row|
  # next if Date.strptime(row['graduation'], '%m/%d/%y') < Date.today # uncomment if we only want active users
  s = get_student(row)
  s.save
end
puts "#{Student.all.count} STUDENTS ADDED"

# Only works after mounting Samba
RESUME_LOCATION = "/Volumes/resumes"
Dir.glob("#{RESUME_LOCATION}/*.pdf").sort.reverse.each do |file_path|
  # By sorting it in reverse order, the most recent pdf file will be first, so the most recent resume will be uploaded first, and the rest will not.

  # File format is: /file/to/resume/locally/netid-randomhash.pdf
  file_key = file_path.split("/")[-1].gsub ".pdf", ""
  netid = file_key.split("-")[0]
  student = Student.first(netid: netid)

  if student && student.resume_url.nil?
    AWS.upload_file(file_path, file_key)
    student.update(resume_url: AWS.fetch_resume(file_key))
    student.update(approved_resume: true)
    puts "#{student.netid}:\tADDED"
  else
    puts "#{netid}:\tDID NOT ADD"
  end
end