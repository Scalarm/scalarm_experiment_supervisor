require 'scalarm/service_core/configuration'
require 'scalarm/service_core/logger'

default_config = {
    'allow_all_origins' => true,
    'allowed_origins' => [
        'https://localhost:3001',
        'http://localhost:3000',
        'https://localhost',
        'http://localhost'
    ]
}

## read secrets.yml
config = default_config.merge(Rails.application.secrets.cors || {})

Scalarm::ServiceCore::Configuration.cors_allow_all_origins = !!config['allow_all_origins']
Scalarm::ServiceCore::Configuration.cors_allowed_origins = config['allowed_origins']

Scalarm::ServiceCore::Logger.set_logger(Rails.logger)