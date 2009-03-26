module Moonshine::Manifest::Rails::Passenger
  # Install the passenger gem
  def passenger_gem
    package "passenger", :ensure => :latest, :provider => :gem
  end

  # Build, install, and enable the passenger apache module. Please see the
  # <tt>passenger.conf.erb</tt> template for passenger configuration options.
  def passenger_apache_module
    # Install Apache2 developer library
    package "apache2-threaded-dev", :ensure => :installed

    file "/usr/local/src", :ensure => :directory

    #have to shell out to another interpreter to make this symlink magic work
    exec "symlink_passenger",
      :command => 'ln -nfs `ruby -rubygems -e \'puts Gem::SourceIndex.from_installed_gems.find_name("passenger").last.loaded_from.gsub(/specifications/,"gems").gsub(/.gemspec/,"/")\'` /usr/local/src/passenger',
      :unless => 'ls -al /usr/local/src/passenger | grep `ruby -rubygems -e \'puts Gem::SourceIndex.from_installed_gems.find_name("passenger").last.version.to_s\'`',
      :require => [
        package("passenger"),
        file("/usr/local/src")
      ]

    # Build Passenger from source
    exec "build_passenger",
      :cwd => configuration[:passenger][:path],
      :command => '/usr/bin/ruby -S rake clean apache2',
      :creates => "#{configuration[:passenger][:path]}/ext/apache2/mod_passenger.so",
      :require => [
        package("passenger"),
        package("apache2-mpm-worker"),
        package("apache2-threaded-dev"),
        exec('symlink_passenger')
      ]

    load_template = "LoadModule passenger_module #{configuration[:passenger][:path]}/ext/apache2/mod_passenger.so"

    file '/etc/apache2/mods-available/passenger.load',
      :ensure => :present,
      :content => load_template,
      :require => [exec("build_passenger")],
      :notify => service("apache2"),
      :alias => "passenger_load"

    file '/etc/apache2/mods-available/passenger.conf',
      :ensure => :present,
      :content => template(File.join(File.dirname(__FILE__), 'templates', 'passenger.conf.erb')),
      :require => [exec("build_passenger")],
      :notify => service("apache2"),
      :alias => "passenger_conf"

    a2enmod 'passenger', :require => [exec("build_passenger"), file("passenger_conf"), file("passenger_load")]
  end

  # Creates and enables a vhost configuration named after your application.
  # Also ensures that the <tt>000-default</tt> vhost is disabled.
  def passenger_site
    file "/etc/apache2/sites-available/#{configuration[:application]}",
      :ensure => :present,
      :content => template(File.join(File.dirname(__FILE__), 'templates', 'passenger.vhost.erb')),
      :notify => service("apache2"),
      :alias => "passenger_vhost",
      :require => exec("a2enmod passenger")

    a2dissite '000-default', :require => file("passenger_vhost")
    a2ensite configuration[:application], :require => file("passenger_vhost")
  end

  def passenger_configure_gem_path
    return configuration[:passenger][:path] if configuration[:passenger] && configuration[:passenger][:path]
    version = begin
      Gem::SourceIndex.from_installed_gems.find_name("passenger").last.version.to_s
    rescue
      `gem install passenger --no-ri --no-rdoc`
      Gem::SourceIndex.from_installed_gems.find_name("passenger").last.version.to_s
    end
    configure(:passenger => { :path => "#{Gem.dir}/gems/passenger-#{version}" })
  end

private

  def passenger_config_boolean(key)
    if key.nil?
      nil
    elsif key == 'Off' || (!!key) == false
      'Off'
    else
      'On'
    end
  end

end