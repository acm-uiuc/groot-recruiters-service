# Copyright © 2017, ACM@UIUC
#
# This file is part of the Groot Project.
#
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.

module JSONBase64Decoder
  def self.decode(blob)
    matches = blob.match(/^data:([A-Za-z\-+\/]+);base64,(.+)$/)
    return -1 if !matches || matches.size != 3
    Hash['type' => matches[1], 'data' => matches[2]]
  end
end
