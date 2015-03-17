class SupervisorScript
  attr_accessor :pid

  def initialize(id, config, experiment_input)
    @experiment_id = config['experiment_id']
    @id = id
    # TODO vailidate config
    # TODO use of id

    config['lower_limit'] = []
    config['upper_limit'] = []
    config['parameters_ids'] = []
    Rails.logger.debug experiment_input
    experiment_input.each do |category|
      category['entities'].each do |entity|
        entity['parameters'].each do |parameter|
          config['lower_limit'].append parameter['min']
          config['upper_limit'].append parameter['max']
          config['parameters_ids'].append "#{category['id']}___#{entity['id']}___#{parameter['id']}"
        end
      end
    end
    if config['start_point'].nil?
      config['start_point'] = []
      config['lower_limit'].zip(config['upper_limit']).each do |e|
        # TODO string params
        config['start_point'].append((e[0]+e[1])/2)
      end
    end
    @config = config
  end

  def start
    # TODO use script id to chose proper optimization script

    script_config = "/tmp/supervisor_script_config_#{@experiment_id.to_s}"
    File.open(script_config, 'w+') {
        |file| file.write(@config.to_json)
    }
    script_log = "log/supervisor_script_log_#{@experiment_id.to_s}"
    path = 'scalarm_supervisor_scrpits/simulated_annealing/anneal.py'
    pid = Process.spawn("python2 #{path} #{script_config}", out: script_log, err: script_log)
    Process.detach(pid)
    @pid = pid
    Rails.logger.debug "New supervisor script pid #{@pid}"
  end

end
