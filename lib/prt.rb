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

    run_command(command, args)
  end

  def run_command(command, args)
    send(:"cmd_#{command}", *args)
  end

  def cmd_info(*args)
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
  end

  def cmd_deptree(*args)
    args.each do |port|
      puts "Deptre for #{port}"
      CRUX.each_dep CRUX::Port.new(port)
    end
  end

  def cmd_installed(*args)
    puts "Installed ports :"
    port_db.ports.each do |port|
      puts [port.name, port.installed_version].join(' ')
    end
  end

  def cmd_remote_sources(*args)
    args.each do |name|
      port = CRUX::Port.new name
      puts "Port #{port.name}"
      port.port_remote_sources.each do |source|
	puts "  #{source}"
      end
    end
  end

end
