require 'semian'
require 'semian/adapter'

module Net
  ProtocolError.include(::Semian::AdapterError)

  class SemianError < ::Net::ProtocolError
    def initialize(semian_identifier, *args)
      super(*args)
      @semian_identifier = semian_identifier
    end
  end

  ResourceBusyError = Class.new(SemianError)
  CircuitOpenError = Class.new(SemianError)
end

module Semian
  module NetHTTP
    include Semian::Adapter

    ResourceBusyError = ::Net::ResourceBusyError
    CircuitOpenError = ::Net::CircuitOpenError

    def semian_identifier
      "http_#{address.tr('.', '_')}_#{port}"
    end

    DEFAULT_ERRORS = [
      ::Timeout::Error, # includes ::Net::ReadTimeout and ::Net::OpenTimeout
      ::TimeoutError, # alias for above
      ::SocketError,
      ::Net::HTTPBadResponse,
      ::Net::HTTPHeaderSyntaxError,
      ::Net::ProtocolError,
      ::EOFError,
      ::IOError,
      ::SystemCallError, # includes ::Errno::EINVAL, ::Errno::ECONNRESET, ::Errno::ECONNREFUSED, ::Errno::ETIMEDOUT, and more
    ].freeze # Net::HTTP can throw many different errors, this tries to capture most of them

    class << self
      attr_accessor :raw_semian_options
      attr_accessor :exceptions

      def retrieve_semian_options_by_identifier(semian_identifier)
        if @raw_semian_options.respond_to?(:call)
          @raw_semian_options.call(semian_identifier)
        else
          @raw_semian_options ||= nil # disabled by default
        end
      end

      def reset_exceptions
        self.exceptions = Semian::NetHTTP::DEFAULT_ERRORS.dup
      end

      def concat_exceptions(exceptions)
        self.exceptions.concat(exceptions)
      end
    end

    Semian::NetHTTP.reset_exceptions

    def raw_semian_options
      Semian::NetHTTP.retrieve_semian_options_by_identifier(semian_identifier)
    end

    def resource_exceptions
      Semian::NetHTTP.exceptions
    end

    def enabled?
      !raw_semian_options.nil?
    end

    def connect
      return super unless enabled?
      acquire_semian_resource(adapter: :http, scope: :connection) do
        super
      end
    end

    def request(*req)
      return super unless enabled?
      acquire_semian_resource(adapter: :http, scope: :query) do
        super
      end
    end
  end
end

Net::HTTP.prepend(Semian::NetHTTP)