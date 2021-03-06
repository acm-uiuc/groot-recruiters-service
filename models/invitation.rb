# Copyright © 2017, ACM@UIUC
#
# This file is part of the Groot Project.
#
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.

require 'erb'

# NOTE: this is not stored in the database.
class Invitation
  def initialize(recruiter, username, password)
    @recruiter = recruiter
    @username = username # Corporate Member name (to sign off email)
    @password = password # Raw, unencrypted recruiter password
    file_path = nil
    case @recruiter.type
    when 'Jobfair'
      @subject = "Invitation to ACM@UIUC Career Week - #{@recruiter.company_name}"
      file_path = '../../views/jobfair_invitation.erb'
    when 'Startup'
      @subject = "Invitation to ACM@UIUC Career Week - #{@recruiter.company_name}"
      file_path = '../../views/startupfair_invitation.erb'
    when 'Outreach'
      @subject = "#{@recruiter.company_name} ACM@UIUC"
      file_path = '../../views/outreach_invitation.erb'
    end
    @html = ERB.new(File.open(File.expand_path(file_path, __FILE__)).read).result(binding)
  end

  def serialize
    {
      subject: @subject,
      to: @recruiter.email,
      body: @html,
      recruiter: @recruiter.serialize
    }
  end
end
