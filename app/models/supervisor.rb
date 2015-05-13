require 'yaml'

class Supervisor

  YAML_READER = lambda {|file, id| YAML::load(IO.read(file)).symbolize_keys.merge({id: id})}

  def self.get_maniphests
    maniphests = []
    Dir[Rails.root.join('supervisors', 'manifest', '*.yml').to_s].each do |file|
      maniphests.append YAML_READER.call file, File.basename(file, File.extname(file))
    end
    maniphests
  end

  def self.get_maniphest(id)
    path = Rails.root.join('supervisors', 'manifest', "#{id}.yml")
    return YAML_READER.call(path, id) if File.exists? path
    nil
  end

  def self.view_path(id)
    path = Dir[Rails.root.join('supervisors', 'views', "#{id}.*")].first.to_s
    File.exists?(path) ? path : nil
  end

end