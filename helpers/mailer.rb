# Copyright © 2017, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.

require 'pony'

module Mailer
  def self.email(subject, body, sender, recipient, ccs=nil, attachment=nil)
    # ccs are comma separated emails that are optionally sent from the UI
    
    # Only send email to corporate locally
    corporate_email = GrootRecruiterService.development? ? "" : "corporate@acm.illinois.edu,"

    Pony.options = {
      subject: subject,
      from: sender,
      cc: "#{corporate_email}#{ccs}",
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
        to: recipient,
        attachments: {
          attachment[:file_name] => attachment[:file_content]
        }
      )
    else
      Pony.mail(to: recipient)
    end
  end
end