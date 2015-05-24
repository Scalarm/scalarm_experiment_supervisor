Configuration
-------------
There are two files with configuration: config/secrets.yml and config/thin.yml.

The "secrets.yml" file is a standard configuration file added in Rails 4 to have a single place for all secrets in
an application. We used this approach in our Scalarm platform.

```
default: &DEFAULT
  information_service_url: "localhost:11300"
  secret_key_base: "<you need to change this - with $rake secret>"
  information_service_user: "<set to custom name describing your Scalarm instance>"
  information_service_pass: "<generate strong password instead of this>"
  # key for symmetric encryption of secret database data - please change it in production installations!
  # NOTICE: this key should be set ONLY ONCE BEFORE first run - if you change or lost it, you will be UNABLE to read encrypted data!
  db_secret_key: "QjqjFK}7|Xw8DDMUP-O$yp"
  supervisor_script_watcher:
    sleep_duration_in_seconds: 60

development:
  <<: *DEFAULT

test:
  <<: *DEFAULT

production:
  secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
  information_service_url: "<%= ENV["INFORMATION_SERVICE_URL"] %>"
  information_service_user: "<%= ENV["INFORMATION_SERVICE_LOGIN"] %>"
  information_service_pass: "<%= ENV["INFORMATION_SERVICE_PASSWORD"] %>"
```

In config/thin.yml configuration of Thin server is stored. There is an example file: config/thin.yml.
