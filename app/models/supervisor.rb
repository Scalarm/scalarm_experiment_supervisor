require 'yaml'

class Supervisor

  YAML_READER = lambda {|file, id| YAML::load(IO.read(file)).symbolize_keys.merge({id: id})}

  def self.getManiphests
    maniphests = []
    Dir[Rails.root.join('supervisors', 'maniphest', '*.yml').to_s].each do |file|
      maniphests.append YAML_READER.call file, File.basename(file, File.extname(file))
    end
    maniphests
  end

  def self.getManiphest(id)
    path = Rails.root.join('supervisors', 'maniphest', "#{id}.yml")
    return YAML_READER.call(path, id) if File.exists? path
    nil
  end

end