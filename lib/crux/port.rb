require 'open3'

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

  fill :path,              :prtget
  fill :installed_files,   :portdb
  fill :installed_version, :portdb
  fill :installed?,        :portdb
  fill :description,       :pkgfile
  fill :maintainer,        :pkgfile
  fill :url,               :pkgfile
  fill :dependencies,      :pkgfile
  fill :group,             :pkgfile
  fill :port_version,      :pkgfile
  fill :port_release,      :pkgfile
  fill :port_sources,      :pkgfile
  fill :source_dir,        :pkgmk
  fill :work_dir,          :pkgmk
  fill :package_dir,       :pkgmk

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

  def fill_from_pkgmk
    sh = <<-'end;'
    PKGMK_SOURCE_MIRRORS=()
    PKGMK_SOURCE_DIR="$PWD"
    PKGMK_PACKAGE_DIR="$PWD"
    PKGMK_WORK_DIR="$PWD/work"
    PKGMK_DOWNLOAD="no"
    PKGMK_IGNORE_FOOTPRINT="no"
    PKGMK_NO_STRIP="no"

    source /etc/pkgmk.conf

    echo PKGMK_SOURCE_DIR="$PKGMK_SOURCE_DIR"
    echo PKGMK_PACKAGE_DIR="$PKGMK_PACKAGE_DIR"
    echo PKGMK_WORK_DIR="$PKGMK_WORK_DIR"
    echo PKGMK_DOWNLOAD="$PKGMK_DOWNLOAD"
    echo PKGMK_IGNORE_FOOTPRINT="$PKGMK_IGNORE_FOOTPRINT"
    echo PKGMK_NO_STRIP="$PKGMK_NO_STRIP"
    echo PKGMK_SOURCE_MIRRORS="${PKGMK_SOURCE_MIRRORS[@]}"
    end;
    lines = []
    Open3.popen3 %[cd "#{path}"; sh] do |stdin, stdout, stderr|
      stdin.puts sh
      stdin.close
      stdout.each_line do |line|
	lines << line.chomp
      end
    end
    lines.each do |line|
      case line
      when /PKGMK_SOURCE_DIR=(.*)/ : @source_dir = $1
      when /PKGMK_PACKAGE_DIR=(.*)/ : @package_dir = $1
      when /PKGMK_WORK_DIR=(.*)/ : @work_dir = $1
      # when /PKGMK_SOURCE_MIRRORS=(.*)/ :
      # when /PKGMK_DOWNLOAD=(.*)/ :
      # when /PKGMK_IGNORE_FOOTPRINT=(.*)/ :
      # when /PKGMK_NO_STRIP=(.*)/ :
      end
    end
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
