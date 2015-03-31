class SupervisorScript < MongoActiveRecord

  def self.collection_name
    'supervisor_scripts'
  end

  def start(id, config)
    self.experiment_id = config['experiment_id']
    self.script_id = id
    # TODO vailidate config
    # TODO use of id
    information_service = InformationService.new

    config['address'] = information_service.get_list_of('experiment_managers').sample
    config['http_schema'] = 'https' # TODO - temporary, change to config entry

    script_config = "/tmp/supervisor_script_config_#{self.experiment_id.to_s}"
    File.open(script_config, 'w+') {
        |file| file.write(config.to_json)
    }
    script_log = "log/supervisor_script_log_#{self.experiment_id.to_s}"
    path = 'scalarm_supervisor_scrpits/simulated_annealing/anneal.py'
    self.pid = Process.spawn("python2 #{path} #{script_config}", out: script_log, err: script_log)
    Process.detach(self.pid)
    Rails.logger.info "New supervisor script pid #{self.pid}"
    self.pid
  end

end
