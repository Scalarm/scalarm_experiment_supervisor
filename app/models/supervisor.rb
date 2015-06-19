require 'yaml'

class Supervisor

  YAML_READER = lambda {|file, id| YAML::load(IO.read(file)).symbolize_keys.merge({id: id})}

  def self.get_manifests
    manifest = []
    Dir[Rails.root.join('supervisors', '*', 'manifest.yml').to_s].each do |file|
      manifest.append YAML_READER.call file, File.dirname(file).split('/').last
    end
    manifest
  end

  def self.get_manifest(id)
    path = Rails.root.join('supervisors', "#{id}", 'manifest.yml')
    return YAML_READER.call(path, id) if File.exists? path
    nil
  end

  def self.view_path(id)
    path = Dir[Rails.root.join('supervisors', "#{id}", 'start_panel.*')].first.to_s
    File.exists?(path) ? path : nil
  end

end