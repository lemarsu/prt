module CRUX

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
      nil
    end

    def port(name)
      @port_dirs.each do |port_dir|
	port = port_dir.port(name)
	return port if port
      end
    end

  end

end
