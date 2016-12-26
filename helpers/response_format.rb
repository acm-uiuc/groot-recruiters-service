# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
module ResponseFormat
    def self.format_response(data, accept)
        if data.nil?
            data = {}
        end
        accept.each do |type|
            return data.to_xml  if type.downcase.eql? 'text/xml'
            return JSON.pretty_generate(data) if type.downcase.eql? 'application/json'
            return data.to_yaml if type.downcase.eql? 'text/x-yaml'
            return data.to_csv  if type.downcase.eql? 'text/csv'
            return JSON.pretty_generate(data)
        end
    end

    # Since groot encodes parameters as json, the request is in JSON and not stored in ruby's params.
    # This method converts the keys to symbols and returns the formatted JSON as a Ruby Hash.
    def self.get_params(raw_payload)
        json_params = JSON.parse(raw_payload) rescue nil

        params = {}
        unless json_params.nil?
            json_params.each { |k, v| params[k.to_sym] = v }
        end

        puts params

        params
    end
end
