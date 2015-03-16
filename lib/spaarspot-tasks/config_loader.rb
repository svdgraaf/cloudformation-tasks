
module SpaarspotTasks
  class ConfigLoader
    CONFIG_FILE = 'config.yml'
    def self.load(config_file = CONFIG_FILE)
      raise ArgumentError, "Invalid null argument provided as input file" if !config_file
      YAML.load_file(config_file)
    rescue
      $stderr.puts "Configuration file #{config_file} could not be loaded."
      raise
    end
  end
end
