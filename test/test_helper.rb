ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '/../../../..'
require 'test/unit'
require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config/environment.rb'))
require 'mocha'
File.dirname(__FILE__) + '../moonshine_config_helper'

class MoonshineConfigHelper
  def self.database_configuration_path
    File.expand_path(File.join(File.dirname(__FILE__), 'database.yml'))
  end
  
  def self.moonshine_configuration_path
    File.expand_path(File.join(File.dirname(__FILE__), 'moonshine.yml'))
  end
end

require 'moonshine'