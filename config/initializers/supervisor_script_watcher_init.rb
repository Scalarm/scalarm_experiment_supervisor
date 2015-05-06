unless Rails.env.test?
  SupervisorRunWatcher.init
  SupervisorRunWatcher.start_watching
end