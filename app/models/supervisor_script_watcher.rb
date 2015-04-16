require 'thread'

##
# This class is used to watch if supervisor scripts are running by periodical call to
# monitoring_loop of SupervisorScript class which is_running flag is true, in given
# moment only one monitoring thread is running.
class SupervisorScriptWatcher
  @@is_running = false
  @@mutex = Mutex.new
  @@sleep_duration_in_seconds = 60

  ##
  # Allows to set custom sleep time
  def self.init
    if Rails.application.secrets.include? :supervisor_script_watcher
      if Rails.application.secrets.supervisor_script_watcher.has_key?("sleep_duration_in_seconds")
        @@sleep_duration_in_seconds = Rails.application.secrets.supervisor_script_watcher["sleep_duration_in_seconds"]
      end
    end
  end

  ##
  # Allows to start monitoring if needed
  def self.start_watching
    @@mutex.synchronize do
      unless @@is_running
        self.watch
        @@is_running = true
      else
        Rails.logger.debug 'Supervisor script watcher is already running'
      end
    end
  end

  private
    def self.watch
      Rails.logger.debug 'Start supervisor script watcher'
      Thread.new do
        while true
          @@mutex.synchronize do
            begin
              Rails.logger.debug 'Supervisor script watch loop'
              running_scripts = SupervisorScript.where(is_running: true).all
              if running_scripts.count == 0
                Rails.logger.debug 'There is no more scripts to watch'
                @@is_running = false
                return
              end
              running_scripts.each do |s|
                s.monitoring_loop
                s.save
              end
            rescue RuntimeError => e
               Rails.logger.info "Error while execution script monitoring loop #{e.to_s}"
               @@is_running = false
               return
            end
          end
          sleep(@@sleep_duration_in_seconds)
        end
      end
  end

end