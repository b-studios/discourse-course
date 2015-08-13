module Course

  VERSION = "0.0.1"

  CONFIG = YAML.load_file(File.dirname(__FILE__) + "/../config/configs.yml")

  class Engine < Rails::Engine
  end

end
