class Bin

  @@commands = []

  def usage(exitcode = 1)
    puts <<''
    usage: prt <command> [port]

    exit exitcode
  end

  def main(*args)
    usage 0 if args.size < 1

    commands = self.class.commands
    command = args.shift.to_sym

    unless commands.include? command
      puts "Unknown command #{command}"
      usage
    end

    run_command(command, get_ports(*args))
  end

  def run_command(name, args)
    commands = []
    command = find_command name
    until command.nil?
      raise "command nil !" if command.nil?
      commands << command
      if command[:prereq]
	command = find_command(command[:prereq])
      else
	command = nil
      end
    end
    commands.reverse!
    p commands.map {|c| c[:name]}
    groupped, straight = commands.partition {|c| c[:groupped]}
    groupped.each do |command|
      args.each do |port|
	command[:block].call port
      end
    end
    args.each do |port|
      straight.each do |command|
	command[:block].call port
      end
    end
  end

  def find_command(name)
    self.class.find_command(name)
  end

  def self.find_command(name)
    @@commands.find {|cn| cn[:name] == name}
  end

  def self.command(name, opts={}, &blk)
    @@commands << opts.merge({
      :name => name,
      :block => blk
    })
  end

  def self.commands
    @@commands.map {|command| command[:name]}
  end

  private



  def get_ports(*ports)
    ports.map do |port_name|
      case port_name.downcase
      when "all" : CRUX::PrtGetConf.new.ports
      when "installed" : CRUX::PortDB.new.ports
      when "outdated" : CRUX.outdated
      else CRUX::Port.new port_name
      end
    end.flatten
  end

end

class Prt < Bin

  command :info do |port|
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

  command :deptree do |port|
    puts "Deptre for #{port.name}"
    CRUX.each_dep port do |port, indent|
      installed = port.installed? ? "[i]" : "[ ]"
      puts "#{installed} #{"  " * indent}#{port.name}"
    end
  end

  command :remote_sources do |port|
    puts "Port #{port.name}"
    port.port_remote_sources.each do |source|
      puts "  #{source}"
    end
  end

  command :list do |port|
    installed = port.installed? ? port.installed_version : "(not installed)"
    puts [port.name, installed].join(' ')
  end

  command :download, :groupped => true do |port|
    puts %[Downloading files for "#{port.name}"]
    # port.download
  end

  command :make, :prereq => :download do |port|
    puts %[Making files for "#{port.name}"]
    # port.make
  end

  command :install, :prereq => :make do |port|
    puts %[Installing files for "#{port.name}"]
  end

end
