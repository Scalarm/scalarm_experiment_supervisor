require 'thread'

##
# This class is used to watch if supervisor scripts are running by periodical call to
# monitoring_loop of SupervisorScript class which is_running flag is true, in given
# moment only one monitoring thread is running.
class SupervisorScriptWatcher
  @@is_running = false
  @@mutex = Mutex.new

  ##
  # Allows to start monitoring if needed
  def self.start_watching
    @@mutex.synchronize do
      unless @@is_running
        self.watch
        @@is_running = true
      end
    end
  end

  private
    def self.watch
      Rails.logger.debug 'Start supervisor script watcher'
      Thread.new do
        sleep(10)
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
          sleep(10)
        end
      end
  end

end