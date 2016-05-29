require 'sinatra/base'

module Sinatra
  module ResponseFormat
    def format_response(data, accept)
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
    end
    helpers ResponseFormat
end
