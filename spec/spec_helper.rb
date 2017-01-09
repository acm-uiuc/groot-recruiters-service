# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'rack/test'
require 'database_cleaner'

require_relative '../app'

def app
  GrootRecruiterService
end

module TestHelpers
  def expect_error(json_response, error_object)
    expect(json_response.to_json).to eq error_object
  end
end

RSpec.shared_examples "invalid parameters" do |parameters, url, method|
  payload = {}
  parameters.each do |key|
    payload[key] = key.to_s
  end
  
  parameters.each do |key|
    it "should not create the model and return an error when #{key} is missing" do
      old_value = payload.delete(key)
      
      if method == "post"
        post url, payload.to_json
      elsif method == "put"
        put url, payload.to_json
      end

      expect(last_response).not_to be_ok
      json_data = JSON.parse(last_response.body)
      expect(json_data['error']).to eq "Missing #{key}"
      
      payload[key] = old_value
    end
  end
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include TestHelpers

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end


  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.disable_monkey_patching!
end
