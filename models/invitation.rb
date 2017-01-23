# Copyright © 2017, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.

require "erb"

# NOTE: this is not stored in the database.
class Invitation
  def initialize(recruiter, username)
    @recruiter = recruiter

    @username = username
    case @recruiter.type
    when "Jobfair"
      @subject = "Invitation to ACM@UIUC Career Week"
      @html = ERB.new(File.read(Dir.pwd + '/views/jobfair_invitation.erb')).result(binding)
    when "Startup"
      @subject = "Invitation to ACM@UIUC Career Week"
      @html = ERB.new(File.read(Dir.pwd + '/views/startupfair_invitation.erb')).result(binding)
    when "Outreach"
      @subject = "#{@recruiter.company_name} ACM@UIUC"
      @html = ERB.new(File.read(Dir.pwd + '/views/outreach_invitation.erb')).result(binding)
    end
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