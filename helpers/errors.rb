# Copyright © 2017, ACM@UIUC
#
# This file is part of the Groot Project.
#
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.

require_relative 'response_format'

module Errors
  INVALID_CREDENTIALS = ResponseFormat.error 'Invalid credentials'
  RECRUITER_NOT_FOUND = ResponseFormat.error 'Recruiter not found'
  STUDENT_NOT_FOUND = ResponseFormat.error 'We could not find your resume or other information in our database.'
  JOB_NOT_FOUND = ResponseFormat.error 'Job not found'
  JOB_APPROVED = ResponseFormat.error 'Job already approved'
  STUDENT_APPROVED = ResponseFormat.error 'Student already approved'
  ACCOUNT_EXPIRED =
    ResponseFormat.error('Your account has expired! ' \
                         'Please reach out to corporate@acm.illinois.edu to renew your account.')
  DUPLICATE_ACCOUNT = ResponseFormat.error 'An account with these credentials already exists.'
  VERIFY_ADMIN_SESSION = ResponseFormat.error 'Corporate session could not be verified'
  FUTURE_DATE = ResponseFormat.error 'You entered a date from the future'
  INVALID_DATE = ResponseFormat.error 'Date was not in a readable format'
  EMAIL_ERROR =
    ResponseFormat.error('There was an error sending an email to your account. ' \
                         'Please contact corporate@acm.illinois.edu for more information.')
  INCORRECT_RESET_CREDENTIALS =
    ResponseFormat.error 'One or more of your account details does not match what we have on record.'
  INELIGIBLE_ACCOUNT =
    ResponseFormat.error('Your account is not eligible to login and view the resume book. ')
end
