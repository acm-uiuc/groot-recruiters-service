# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
module JSONBase64Decoder
    def self.decode(blob)
        matches =  blob.match(/^data:([A-Za-z\-+\/]+);base64,(.+)$/)
        if !matches || matches.size != 3
            puts "WARNING: Blob is not a valid document"
            return -1;
        end
        buffer = Hash["type" => matches[1], "data" => matches[2]]
        return buffer
    end
end
