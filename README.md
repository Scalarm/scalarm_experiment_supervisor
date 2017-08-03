[![Build Status](https://travis-ci.org/Dragner8/scalarm_experiment_supervisor.svg?branch=master)](https://travis-ci.org/Dragner8/scalarm_experiment_supervisor)    [![](https://images.microbadger.com/badges/version/scalarm/scalarm_experiment_supervisor.svg)](https://microbadger.com/images/scalarm/scalarm_experiment_supervisor "Get your own version badge on microbadger.com")   [![](https://images.microbadger.com/badges/image/scalarm/scalarm_experiment_supervisor.svg)](https://microbadger.com/images/scalarm/scalarm_experiment_supervisor "Get your own image badge on microbadger.com")  

Configuration
-------------
There are two files with configuration: config/secrets.yml and config/thin.yml.

The "secrets.yml" file is a standard configuration file added in Rails 4 to have a single place for all secrets in
an application. We used this approach in our Scalarm platform.

```
default: &DEFAULT
  ## cookies enctyption key - set the same in each ExperimentManager to allow cooperation
  secret_key_base: "<you need to change this - with $rake secret>"

  ## InformationService - a service locator
  information_service_url: "localhost:11300"
  information_service_user: "<set to custom name describing your Scalarm instance>"
  information_service_pass: "<generate strong password instead of this>"
  ## uncomment, if you want to communicate through HTTP with Scalarm Information Service
  # information_service_development: true

  ## Database configuration
  ## name of MongoDB database, it is scalarm_db by default
  database:
    db_name: 'scalarm_db'
    ## key for symmetric encryption of secret database data - please change it in production installations!
    ## NOTICE: this key should be set ONLY ONCE BEFORE first run - if you change or lost it, you will be UNABLE to read encrypted data!
    db_secret_key: "QjqjFK}7|Xw8DDMUP-O$yp"

  supervisor_script_watcher:
    ## Set an interval of script watching (checking if scripts are alive)
    sleep_duration_in_seconds: 60
    ## Set retrying limit of monitoring loop after error
    errors_limit: 3
    
  ## Path where logs are moved after supervisor run execution finish.
  # log_archive_path: /some/path

  ## Uncomment, if you want to communicate through HTTP with Scalarm Storage Manager
  # storage_manager_development: true

  ## if you want to communicate with Storage Manager using a different URL than the one stored in Information Service
  # storage_manager_url: "localhost:20000"
  ## if you want to pass to Simulation Manager a different URL of Information Service than the one mentioned above
  # sm_information_service_url: "localhost:37128"

production:
  <<: *DEFAULT
  ## In production environments some settings should not be stored in configuration file
  ## for security reasons.

  secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
  information_service_url: "<%= ENV["INFORMATION_SERVICE_URL"] %>"
  information_service_user: "<%= ENV["INFORMATION_SERVICE_LOGIN"] %>"
  information_service_pass: "<%= ENV["INFORMATION_SERVICE_PASSWORD"] %>"
  database:
    db_secret_key: "<%= ENV["DB_SECRET_KEY"] %>"

development:
  <<: *DEFAULT

test:
  <<: *DEFAULT
```

In config/thin.yml configuration of Thin server is stored. There is an example file: config/thin.yml.
