# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.

require 'pony'

module Mailer
  def self.email(subject, body, credentials, to, attachment=nil)
    Pony.options = {
      subject: subject,
      body: body,
      via: :smtp,
      via_options: {
        address: 'smtp.gmail.com',
        port: '587',
        enable_starttls_auto: true,
        user_name: credentials[:email],
        password: credentials[:password],
        domain: 'localhost.localdomain'
      }
    }

    if attachment
      Pony.mail(
        to: to,
        cc: credentials[:email],
        attachments: {
          attachment[:file_name] => attachment[:file_content]
        }
      )
    else
      Pony.mail(
        to: to,
        cc: credentials[:email]
      )
    end
  end
end