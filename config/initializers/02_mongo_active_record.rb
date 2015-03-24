require 'mongo_active_record'

# class initizalization
config = YAML.load_file(File.join(Rails.root, 'config', 'scalarm.yml'))

database = config['db_name']

if Rails.env.test?
  database = "#{database}_test"
end

slog('mongo_active_record', "Connecting to 'localhost', database: #{database}")

unless MongoActiveRecord.connection_init('localhost', database)
  information_service = InformationService.new
  storage_manager_list = information_service.get_list_of('db_routers')

  unless storage_manager_list.blank?
    db_router_url = storage_manager_list.sample
    slog('mongo_active_record', "Connecting to '#{db_router_url}'")
    MongoActiveRecord.connection_init(db_router_url, database)
  end
end
