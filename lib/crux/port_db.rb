module CRUX

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

    def ports
      read_db unless @ports
      @ports
    end

    def search_info(name)
      read_db unless @ports_cache
      @ports_cache.find {|port| port[:name] == name}
    end

    private

    def read_db
      @ports = []
      @ports_cache = []
      each_port_entry do |port_name, version, files|
	@ports << make_port(port_name, version, files)
	@ports_cache << {:name => port_name, :files => files, :version => version}
      end
    end

    def each_port_entry
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

end
