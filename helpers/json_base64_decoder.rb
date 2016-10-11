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
