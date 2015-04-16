unless Rails.env.test?
  SupervisorScriptWatcher.init
  SupervisorScriptWatcher.start_watching
end