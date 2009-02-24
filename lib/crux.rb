require 'crux/port'
require 'crux/port_db'
require 'crux/port_dir'
require 'crux/prt_get_conf'

module CRUX
  def self.each_installed_ports(&blk)
    PortDB.new.ports.each(&blk)
  end
end
