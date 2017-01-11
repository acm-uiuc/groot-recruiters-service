# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.

require 'pry'

module ResponseFormat
    def self.error(error)
        { error: error }.to_json
    end

    def self.data(data)
        if data.is_a? Array
          { error: nil, data: data.map { |e| e.serialize } }.to_json  
        else
          { error: nil, data: data.serialize }.to_json
        end
    end
    
    def self.message(msg)
        { error: nil, data: {}, message: msg }.to_json
    end

    # Since groot encodes parameters as json, the request is in JSON and not stored in ruby's params.
    # This method converts the keys to symbols and returns the formatted JSON as a Ruby Hash.
    def self.get_params(raw_payload)
        json_params = JSON.parse(raw_payload) rescue nil

        params = {}
        unless json_params.nil?
            json_params.each { |k, v| params[k.to_sym] = v }
        end
        params
    end
end
