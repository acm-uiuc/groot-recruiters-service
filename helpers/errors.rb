require_relative 'response_format'

module Errors
  INVALID_CREDENTIALS = ResponseFormat.error "Invalid credentials"
  RECRUITER_NOT_FOUND = ResponseFormat.error"Recruiter not found"
  USER_NOT_FOUND = ResponseFormat.error "User not found"
  JOB_NOT_FOUND = ResponseFormat.error "Job not found"
  JOB_APPROVED = ResponseFormat.error "Job already approved"
  STUDENT_APPROVED = ResponseFormat.error "Student already approved"

  ACCOUNT_EXPIRED = ResponseFormat.error "Your account has expired! Please reach out to corporate@acm.illinois.edu so that your account can be renewed!"
  DUPLICATE_ACCOUNT = ResponseFormat.error "An account with these credentials already exists."

  VERIFY_CORPORATE_SESSION = ResponseFormat.error "Corporate session could not be verified"
  VERIFY_GROOT = ResponseFormat.error "Request did not originate from groot"
end