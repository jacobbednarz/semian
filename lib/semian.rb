require 'semian/semian'

class Semian
  class << self
    def register(name, tickets: 0, timeout: 1)
      resource = Resource.new(name, tickets, timeout)
      resources[name] = resource
    end

    def [](name)
      resources[name]
    end

    def resources
      @resources ||= {}
    end
  end
end