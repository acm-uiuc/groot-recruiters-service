require 'yaml'

module Config
    def self.load_config(section)
        config = YAML.load_file(__dir__ + "/../config/secrets.yaml")
        return config[section]
    end
end
