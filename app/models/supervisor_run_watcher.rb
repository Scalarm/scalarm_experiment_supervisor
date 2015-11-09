require 'thread'

##
# This class is used to watch if supervisor scripts are running by periodical call to
# monitoring_loop of SupervisorScript class which is_running flag is true, in given
# moment only one monitoring thread is running.
class SupervisorRunWatcher
  @is_running = false
  @mutex = Mutex.new
  @sleep_duration_in_seconds = 60
  @errors_limit = 3

  ##
  # Allows to set custom sleep time
  def self.init
    if Rails.application.secrets.include? :supervisor_script_watcher
      if Rails.application.secrets.supervisor_script_watcher.has_key?('sleep_duration_in_seconds')
        @sleep_duration_in_seconds = Rails.application.secrets.supervisor_script_watcher['sleep_duration_in_seconds']
      end
      if Rails.application.secrets.supervisor_script_watcher.has_key?('errors_limit')
        @errors_limit = Rails.application.secrets.supervisor_script_watcher['errors_limit']
      end
    end
  end

  ##
  # Allows to start monitoring if needed
  def self.start_watching
    @mutex.synchronize do
      if @is_running
        Rails.logger.debug 'Supervisor script watcher is already running'
      else
        Rails.logger.debug 'Start supervisor script watcher'
        Thread.new do
          self.watching_loop
        end
        @is_running = true
      end
    end
  end


  def self.watching_loop
    errors_count = {}
    loop do
      @mutex.synchronize do
        begin
          Rails.logger.debug 'Supervisor script watch loop'
          runs = SupervisorRun.find_all_by_query(is_running: true, is_error: false)
          if runs.count == 0
            Rails.logger.debug 'There are no more scripts to watch'
            @is_running = false
            return
          end
          runs.each do |run|
            id = run.id.to_sym
            begin
              run.monitoring_loop!
              errors_count[id] = 0
            rescue => e
              errors_count[id] = 0 unless errors_count.has_key? id
              if errors_count[id] < @errors_limit
                Rails.logger.warn "An error occurred during supervisor run monitoring execution [#{run.id}]:#{e.to_s}"
                errors_count[id] += 1
              else
                Rails.logger.error "Fatal error occurred during supervisor run monitoring execution [#{run.id}], "\
                                    "execution stopped : #{e.to_s}\n#{e.backtrace.join("\n")}"
                run.set_error!(e.to_s)
              end
            end
          end
        rescue => e
           Rails.logger.error "Fatal error occurred during supervisor runs watcher thread: #{e.to_s}\n"\
                              "#{e.backtrace.join("\n")}"
           @is_running = false
           return
        end
      end
      sleep(@sleep_duration_in_seconds)
    end
  end

end
