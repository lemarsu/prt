require 'crux/port'
require 'crux/port_db'
require 'crux/port_dir'
require 'crux/prt_get_conf'

module CRUX
  def self.each_installed_ports(&blk)
    PortDB.new.ports.each(&blk)
  end

  def self.each_dep(port, indent = 0)
    puts "#{"  " * indent}#{port.name}"
    port.port_dependencies.each {|dep| each_dep(dep,indent + 1)}
  end

end
