# Copyright © 2016, ACM@UIUC
#
# This file is part of the Groot Project.  
# 
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.
require 'yaml'

module Config
    def self.load_config(section)
      config = YAML.load_file(__dir__ + "/../config/secrets.yaml")
      config[section]
    end

    def self.load_db(section)
      config = YAML.load_file(__dir__ + "/../config/database.yaml")
      config[section]
    end
end
