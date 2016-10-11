require 'yaml'

module Config
    def self.config(section)
        config = YAML.load_file("config/secrets.yaml")
        return config[section]
    end
end
