module CRUX

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

end
