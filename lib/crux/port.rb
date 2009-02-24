module CRUX
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
  fill :port_version, :pkgfile
  fill :port_release, :pkgfile
  fill :port_sources, :pkgfile

  def initialize(name)
    @name = name
  end

  def port_dependencies
    @port_dependencies ||= dependencies.map {|dep| Port.new(dep)}
  end

  def pkgfile
    return nil unless path
    File.join(path, "Pkgfile")
  end

  def port_full_version
    [port_version, port_release] * '-'
  end

  def port_remote_sources
    (port_sources||[]).grep %r[^(?:f|ht)tp://]
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
    fill_from_pkgfile_raw
    fill_from_pkgfile_via_sh
  end

  def fill_from_pkgfile_raw
    return if pkgfile.nil?
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

  def fill_from_pkgfile_via_sh
    return if pkgfile.nil?
    ret = `(cat #{pkgfile}; echo 'echo $name $version $release ${source[@]}')|sh`
    name, version, release, *sources = ret.split(/\s+/)
    @port_version = version
    @port_release = release
    @port_sources = sources
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
end
