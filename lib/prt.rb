class Prt

  def main(*args)
    if args.size < 1
      STDERR.puts "I need at least a name"
      exit 1
    end

    port_db = CRUX::PortDB.new
    prtget_conf = CRUX::PrtGetConf.new
    args.each do |name|
      port = CRUX::Port.new name
      # port = port_db.port(name)
      # port = prtget_conf.port(name)
      p port.path
      p port.installed?
      p port.installed_version
      p port.description
      p port.maintainer
      p port.url
      p port.dependencies
      p port.port_full_version
      p port.port_remote_sources
      # p port
      puts
    end

    CRUX.each_dep CRUX::Port.new('apache')

    # puts "Installed ports :"
    # port_db.ports.each do |port|
    #   puts [port.name, port.installed_version].join ' '
    # end

    CRUX.each_installed_ports do |port|
      puts "Port #{port.name}"
      port.port_remote_sources.each do |source|
	puts "  #{source}"
      end
    end

  end

end
