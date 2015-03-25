require 'mongo_active_record'

unless Rails.env.test?
  # class initizalization
  config = YAML.load_file(File.join(Rails.root, 'config', 'scalarm.yml'))

  slog('mongo_active_record', "Connecting to 'localhost', database: #{config['db_name']}")

  MongoActiveRecord.connect_to_db_with_name config['db_name']
end