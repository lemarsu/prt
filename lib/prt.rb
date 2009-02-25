class Bin

  @@commands = []

  class Error < Exception; end

  class Command
    attr_reader :name
    attr_accessor :error
    def initialize(name, opts={}, &blk)
      @name = name
      @opts = opts
      @block = blk
    end

    def call(port)
      self.error = false
      @block.call port
    rescue Error => ex
      self.error = ex
    # rescue Exception => ex
    #   puts ex, ex.message, ex.backtrace
    #   self.error = true
    end

    def error?
      @error
    end

    def depends
      @opts[:depends]
    end

    def groupped?
      @opts[:groupped]
    end
  end

  CommandError = Struct.new(:command, :error, :port)

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

  def run_command(name, ports)
    commands = command_list(name)
    groupped, straight = split_groupped_commands(commands)
    command_errors = []
    groupped.each do |command|
      ports.each do |port|
	command.call port
	if command.error?
	  puts "Error with #{port.name}: #{error_message(command.error)}"
	  command_errors << CommandError.new(command, command.error, port)
	  ports.delete port
	end
      end
    end
    ports.each do |port|
      straight.each do |command|
	command.call port
	if command.error?
	  puts "Error with #{port.name}: #{error_message(command.error)}"
	  command_errors << CommandError.new(command, command.error, port)
	  break
	end
      end
    end
    show_errors(command_errors)
  end

  def show_errors(command_errors)
    puts
    last_command = nil
    command_errors.each do |ce|
      if last_command != ce.command
	puts "Errors for command #{ce.command.name}"
      end
      puts " - #{ce.port.name}: #{error_message(ce.error)}"
    end
  end

  def self.find_command(name)
    @@commands.find {|c| c.name == name}
  end

  def self.command(name, opts={}, &blk)
    @@commands << Command.new(name, opts, &blk)
  end

  def self.commands
    @@commands.map {|command| command.name}
  end

  private

  def error_message(ex)
    message = ex.class.to_s
    message += ": #{ex.message}" if ex.message.size > 0 && ex.message != ex.class.to_s
    # message += ": #{ex.message}" unless ex.message.empty?
    message
  end

  def command_list(name)
    commands = []
    command = find_command name
    until command.nil?
      commands << command
      command = command.depends ?
	find_command(command.depends) : nil
    end
    commands.reverse
  end

  def find_command(name)
    self.class.find_command(name)
  end

  def split_groupped_commands(commands)
    groupped, straight = [], []
    find_groupped = false
    commands.reverse.each do |command|
      if find_groupped || command.groupped?
	find_groupped = true
	groupped.unshift command
      else
	straight.unshift command
      end
    end
    [groupped, straight]
  end

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

  class FetchError < Error; end
  class MakeError < Error; end
  class InstallError < Error; end

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

  command :make, :depends => :download do |port|
    puts %[Making files for "#{port.name}"]
    # port.make
  end

  command :install, :depends => :make do |port|
    puts %[Installing files for "#{port.name}"]
  end

end
