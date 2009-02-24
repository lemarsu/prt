class Prt

  def usage(exitcode = 1)
    puts <<''
    usage: prt <command> [port]

    exit exitcode
  end

  def main(*args)
    usage 0 if args.size < 1

    commands = public_methods.grep(/^cmd_/).map{|pm| pm.gsub(/^cmd_/,'')}
    command = args.shift

    unless commands.include? command
      puts "Unknown command #{command}"
      usage
    end

    run_command(command, get_ports(*args))
  end

  def run_command(command, args)
    send(:"cmd_#{command}", *args)
  end

  def cmd_info(*args)
    args.each do |port|
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
  end

  def cmd_deptree(*args)
    args.each do |port|
      puts "Deptre for #{port.name}"
      CRUX.each_dep port do |port, indent|
	installed = port.installed? ? "[i]" : "[ ]"
	puts "#{installed} #{"  " * indent}#{port.name}"
      end
    end
  end

  def cmd_installed(*args)
    puts "Installed ports :"
    port_db.ports.each do |port|
      puts [port.name, port.installed_version].join(' ')
    end
  end

  def cmd_remote_sources(*args)
    args.each do |port|
      puts "Port #{port.name}"
      port.port_remote_sources.each do |source|
	puts "  #{source}"
      end
    end
  end

  private

  def get_ports(*ports)
    ports.map do |port_name|
      case port_name.downcase
      when "all" : CRUX::PrtGetConf.new.ports
      when "installed" : CRUX::PortDB.new.ports
      else CRUX::Port.new port_name
      end
    end.flatten
  end

end
