# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require 'ci/reporter/rake/minitest'

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

LOCAL_MONGOS_PATH = 'bin/mongos'

namespace :service do
  desc 'Start the service'
  task :start => [:ensure_config, :validate_config, :environment] do
    puts 'puma -C config/puma.rb'
    %x[puma -C config/puma.rb]
  end

  desc 'Stop the service'
  task :stop => :environment do
    puts 'pumactl -F config/puma.rb -T scalarm stop'
    %x[pumactl -F config/puma.rb -T scalarm stop]
  end

  desc 'Restart the service'
  task restart: [:stop, :start] do
  end

  desc 'Create default configuration files if these do not exist'
  task :ensure_config do
    copy_example_config_if_not_exists('config/secrets.yml')
    copy_example_config_if_not_exists('config/puma.rb')
  end

  desc 'Validate config files entries'
  task :validate_config do
    validate_secrets
  end
end

task :check_test_env do
  raise 'RAILS_ENV not set to test' unless Rails.env.test?
end

namespace :test do |ns|
  # add dependency to check_test_env for each test task
  ns.tasks.each do |t|
    task_name = t.to_s.match(/test:(.*)/)[1]
    task task_name.to_sym => [:check_test_env] unless task_name.blank?
  end
end

namespace :ci do
  task :all => ['ci:setup:minitest', 'test']
end

namespace :db_router do
  desc 'Start MongoDB router'
  task :start, [:debug] => [:environment, :setup] do |t, args|
    information_service = InformationService.instance

    config_services = information_service.get_list_of('db_config_services')
    puts "Config services: #{config_services.inspect}"
    unless config_services.blank?
      config_service_url = config_services.sample
      start_router(config_service_url) if config_service_url
    end
  end

  task :stop, [:debug] => [:environment] do |t, args|
    stop_router
  end

  task :setup do
    install_mongodb unless mongos_path
    _validate_db_router
  end

  desc 'Check dependencies for db_router'
  task :validate do
    begin
      _validate_db_router
    rescue => e
      puts "Error on validation: #{e}"
      puts "Please read documentation and run db_router:setup"
      raise
    end
  end
end

# ================ UTILS
def start_router(config_service_url)
  bin = mongos_path
  puts "Using: #{bin}"
  puts `#{bin} --version 2>&1`
  router_cmd = "#{mongos_path} --bind_ip localhost --configdb #{config_service_url} --logpath log/db_router.log --fork --logappend"
  puts router_cmd
  puts %x[#{router_cmd}]
end

def stop_router
  proc_name = "#{mongos_path} .*"
  out = %x[ps aux | grep "#{proc_name}"]
  processes_list = out.split("\n").delete_if { |line| line.include? 'grep' }

  processes_list.each do |process_line|
    pid = process_line.split(' ')[1]
    puts "kill -15 #{pid}"
    system("kill -15 #{pid}")
  end
end

def install_mongodb
  puts 'Downloading MongoDB...'
  base_name = get_mongodb
  puts 'Unpacking MongoDB and copying files...'
  `tar -zxvf #{base_name}.tgz`
  raise "Cannot unpack #{base_name}.tgz archive" unless $?.to_i == 0
  `cp #{base_name}/bin/mongos bin/mongos`
  raise "Cannot copy #{base_name}/bin/mongos file" unless $?.to_i == 0
  `rm -r #{base_name} #{base_name}.tgz`
  puts 'Installed MongoDB mongos in Scalarm directory'
end

def get_mongodb(version='2.6.5')
  os, arch = os_version
  mongo_name = "mongodb-#{os}-#{arch}-#{version}"
  download_file_https('fastdl.mongodb.org', "/#{os}/mongodb-#{os}-#{arch}-#{version}.tgz", "#{mongo_name}.tgz")
  mongo_name
end

def download_file_https(domain, path, name)
  require 'net/https'
  address = "https://#{domain}/#{path}"
  puts "Fetching #{address}..."
  Net::HTTP.start(domain) do |http|
    resp = http.get(path)
    open(name, "wb") do |file|
      file.write(resp.body)
    end
  end
  puts "Downloaded #{address} -> #{name}"
  name
end

def _validate_db_router
  print 'Checking bin/mongos... '
  raise "No /bin/mongos file found and no mongos in PATH" unless mongos_path
  puts 'OK'
end

def mongos_path
  `ls #{LOCAL_MONGOS_PATH} >/dev/null 2>&1`
  if $?.to_i == 0
    LOCAL_MONGOS_PATH
  else
    `which mongos > /dev/null 2>&1`
    if $?.to_i == 0
      'mongos'
    else
      nil
    end
  end
end

def os_version
  require 'rbconfig'
  os_arch = RbConfig::CONFIG['arch']
  os = case os_arch
         when /darwin/
           'osx'
         when /cygwin|mswin|mingw|bccwin|wince|emx/
           'win32'
         else
           'linux'
       end
  arch = case os_arch
           when /x86_64/
             'x86_64'
           when /i686/
             'i686'
         end
  [os, arch]
end

def copy_example_config_if_not_exists(base_name, prefix='example')
  config = base_name
  example_config = "#{base_name}.example"

  unless File.exists?(config)
    puts "Copying #{example_config} to #{config}"
    FileUtils.cp(example_config, config)
  end
end

def validate_secrets
  if Rails.application.secrets.include? :log_archive_path
    archive_log_path = Rails.application.secrets.log_archive_path
    unless Dir.exist? archive_log_path
      raise "ERROR: Invalid path in config file (config/secrets.yml) entry log_archive_path: #{archive_log_path}"
    end
  end
end
