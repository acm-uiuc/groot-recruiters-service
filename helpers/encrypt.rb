# Copyright © 2017, ACM@UIUC
#
# This file is part of the Groot Project.
#
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.

require 'bcrypt'

module Encrypt
  def self.encrypt_password(password)
    BCrypt::Password.create(password)
  end

  def self.generate_encrypted_password
    password = (('a'..'z').to_a + ('0'..'9').to_a).sample(8).join
    return password, encrypt_password(password)
  end

  def self.valid_password?(encrypted_password, raw_password)
    password = BCrypt::Password.new(encrypted_password)
    password == raw_password
  end
end
