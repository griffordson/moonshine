class MoonshineConfigHelper
  def self.database_configuration_path
    File.expand_path(File.join(ENV['RAILS_ROOT'], 'config', 'database.yml'))
  end
  
  def self.moonshine_configuration_path
    File.expand_path(File.join(ENV['RAILS_ROOT'], 'config', 'moonshine.yml'))
  end
end