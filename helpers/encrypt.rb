# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
module Encrypt
  def self.encrypt_password(password)
    encryption = Config.load_config('encryption')
    Digest::MD5.hexdigest(encryption['secret'] + random_password)
  end

  def self.generate_encrypted_password
    password = ('A'..'z').to_a.sample(8).join
    
    return password, self.encrypt_password(password)
  end
end