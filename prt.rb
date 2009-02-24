#!/usr/bin/env ruby
#

require 'rubygems'

class Port
  attr_reader :name

  def self.fill(attr, *froms)
    method_name = attr
    attr = attr.to_s.chop if attr.to_s =~ /\?$/
    fetch_loop = froms.map do |from|
      <<-"end;"
	fill_from_#{from}
	return @#{attr} if @#{attr}
      end;
    end.join
    module_eval <<-"end;"
      attr_writer :#{attr}
      def #{method_name}
	return @#{attr} if @#{attr}
	#{fetch_loop}
	@#{attr}
      end
    end;
  end

  fill :path, :prtget
  fill :installed_files, :portdb
  fill :installed_version, :portdb
  fill :installed?, :portdb
  fill :description, :pkgfile
  fill :maintainer, :pkgfile
  fill :url, :pkgfile
  fill :dependencies, :pkgfile
  fill :group, :pkgfile

  def initialize(name)
    @name = name
  end

  def port_dependencies
    @port_dependencies ||= dependencies.map {|dep| Port.new(dep)}
  end

  def pkgfile
    File.join(path, "Pkgfile")
  end

  private

  def fill_from_prtget
    @path = prtget.get_path(name)
  end

  def fill_from_portdb
    infos = port_db.search_info name
    if infos
      self.installed = true
      self.installed_files = infos[:files]
      self.installed_version = infos[:version]
    else
      self.installed = false
    end
  end

  def fill_from_pkgfile
    File.open pkgfile do |f|
      f.each_line do |line|
	case line
	when /^#\s+Description:\s*(.*?)\s*$/
	  @description = $1
	when /^#\s+Maintainer:\s*(.*?)\s*$/
	  @maintainer = $1
	when /^#\s+URL:\s*(.*?)\s*$/
	  @url = $1
	when /^#\s+Depends on:\s*(.*?)\s*$/
	  @dependencies = $1.split(/[ ,]+/)
	when /^#\s+Group:\s*(.*?)\s*$/
	  @group = $1
	end
      end
    end
    @dependencies ||= []
  end

  def port_db
    self.class.port_db
  end

  def prtget
    self.class.prtget
  end

  def self.port_db
    @@port_db ||= PortDB.new
  end

  def self.prtget
    @@prtget ||= PrtGetConf.new
  end
end

class PortDB
  DB_PATH = '/var/lib/pkg/db'
  private :initialize

  def self.default
    @@default ||= new
  end

  def port(name)
    read_db unless @ports
    @ports.find {|port| port.name == name}
  end

  def search_info(name)
    each_port_entry do |name, version, files|
      return {:name => name, :version => version, :files => files}
    end
  end

  private

  def read_db
    each_port_entry do |port_name, version, files|
      @ports << make_port(port_name, version, files)
    end
  end

  def each_port_entry
    @ports = []
    File.open(DB_PATH) do |f|
      port_name, version, files = nil, nil, []
      f.each_line do |line|
	line.chomp!
	if port_name && version && line == ''
	  yield port_name, version, files
	  port_name, version, files = nil, nil, []
	  next
	end
	next port_name = line unless port_name
	next version = line unless version
	files << line
      end
    end
  end

  def make_port(name, version, files)
    port = Port.new(name)
    port.installed_version = version
    port.installed_files = files
    port.installed = true
    port
  end
end

class PrtGetConf
  CONF_PATH = '/etc/prt-get.conf'
  def initialize(file = CONF_PATH)
    @port_dirs = []
    prtdir_re = /^\s*prtdir\s+/
    File.open(file) do |f|
      f.each_line do |line|
	next unless line =~ prtdir_re
	@port_dirs << line.chomp.gsub(prtdir_re, '')
      end
    end
    @port_dirs.reject! {|dir| !File.readable?(dir)}
    @port_dirs.map! {|dir| PortDir.new dir}
  end

  def port_dirs
    @port_dirs
  end

  def get_path(name)
    @port_dirs.each do |port_dir|
      path = port_dir.get_path(name)
      return path if path
    end
  end

  def port(name)
    @port_dirs.each do |port_dir|
      port = port_dir.port(name)
      return port if port
    end
  end

end

class PortDir
  attr_reader :path
  def initialize(path)
    @path = path
  end

  def get_path(name)
    path = "#@path/#{name}/Pkgfile"
    return nil unless File.exists?(path)
    File.dirname path
  end

  def port(name)
    path = "#@path/#{name}/Pkgfile"
    return nil unless File.exists?(path)
    port = Port.new name
    port.path = File.dirname path
    port
  end

  def inspect
    "#<PortDir #{path.inspect}>"
  end
end

if $0 == __FILE__

  if ARGV.size < 1
    STDERR.puts "I need at least a name"
    exit 1
  end

  port_db = PortDB.new
  prtget_conf = PrtGetConf.new
  ARGV.each do |name|
    port = Port.new name
    # port = port_db.port(name)
    # port = prtget_conf.port(name)
    p port.path
    p port.installed?
    p port.installed_version
    p port.description
    p port.maintainer
    p port.url
    p port.dependencies
    # p port
    puts
  end
end
