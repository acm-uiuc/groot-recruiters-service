# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
module Mailer
  def self.email(subject, body, sender)
    credentials = Config.load_config('email')

    Pony.options = {
      subject: subject,
      body: html_body,
      via: :smtp,
      via_options: {
        address: 'smtp.gmail.com',
        port: '587',
        enable_starttls_auto: true,
        user_name: credentials['username'],
        password: credentials['password'],
        authentication: :plain,
        domain: 'localhost.localdomain'
      }
    }
    Pony.mail(to: sender)
  end
end