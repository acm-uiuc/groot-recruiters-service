# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.

require 'pony'

module Mailer
  def self.email(subject, body, from, to, attachment=nil)
    Pony.options = {
      subject: subject,
      from: from,
      cc: from,
      body: body,
      via: :smtp,
      via_options: {
        address: 'express-smtp.cites.uiuc.edu',
        port: '25',
        :enable_starttls_auto => false,
      }
    }

    if attachment
      Pony.mail(
        to: to,
        attachments: {
          attachment[:file_name] => attachment[:file_content]
        }
      )
    else
      Pony.mail(to: to)
    end
  end
end