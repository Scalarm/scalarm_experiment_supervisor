source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4.1.15'
# Use SCSS for stylesheets
# gem 'sass-rails', '~> 4.0.3'
# Use Uglifier as compressor for JavaScript assets
# gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
# gem 'coffee-rails', '~> 4.0.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer',  platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'

# not used
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
# gem 'turbolinks'

# jbuilder not used
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0',          group: :doc

# disabled due to problems with invoking rails console
# Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
# gem 'spring',        group: :development

gem 'bson'
gem 'bson_ext'
gem 'mongo', '~> 1.12'
# mongo session store 5.1 supports mongo 1.12
# it can be changed to 6.0 if mongo will be upgraded to 2.x
# Disabling due to bugs
#gem 'mongo_session_store-rails4',
#    git: 'git://github.com/kliput/mongo_session_store.git',
#    branch: 'issue-31-mongo_store-deserialization'

gem 'mocha', '~> 1.1.0', group: :test
gem 'ci_reporter_minitest', group: :test

gem 'rdoc', '~> 4.2.0'

gem 'rest-client', '~> 1.8'

gem 'haml'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

gem 'puma'

# for local development - set path to scalarm-database
#gem 'scalarm-database', path: '/home/jliput/Scalarm/scalarm-database'
gem 'scalarm-database', '~> 1.4', git: 'git://github.com/Scalarm/scalarm-database.git'

# for local development - set path to scalarm-core
# gem 'scalarm-service_core', path: '/Users/jliput/Scalarm/scalarm-service_core'
gem 'scalarm-service_core', '~> 1.3', git: 'git://github.com/Scalarm/scalarm-service_core.git'
