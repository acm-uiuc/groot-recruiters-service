# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.

require "erb"

# NOTE: this is not stored in the database.
class Invitation
  attr_reader :html

  def initialize(recruiter)
    @recruiter = recruiter

    # TODO get username from UI somehow
    @username = "ENTER USERNAME"
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

  def send
    Mailer.mail(@subject, @html_body, @recruiter.email)
  end

  def serialize
    credentials = Config.load_config("email")
    {
      subject: @subject,
      from: credentials['username'],
      to: @recruiter.email,
      body: @html,
      recruiter: @recruiter.serialize
    }
  end
end