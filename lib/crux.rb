require 'crux/port'
require 'crux/port_db'
require 'crux/port_dir'
require 'crux/prt_get_conf'

module CRUX
  def self.each_installed_ports(&blk)
    PortDB.new.ports.each(&blk)
  end

  def self.each_dep(port, indent = 0, &blk)
    yield port, indent
    port.port_dependencies.each {|dep| each_dep(dep,indent + 1, &blk)}
  end

  def self.outdated
    CRUX::PortDB.new.ports.select do |port|
      !port.path.nil? && port.installed_version != port.port_full_version
    end
  end

end
