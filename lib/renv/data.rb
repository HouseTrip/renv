require 'renv'
require 'delegate'

module Renv
  class Data
    extend Forwardable

    def initialize(payload = '')
      @data = _parse(payload)
    end

    delegate [:[], :delete] => :@data

    def []=(key, value)
      _assert(key =~ /^[A-Z0-9_]+$/, 'Key must be uppercase letters, digits, and underscores')
      @data[key] = value
    end

    def dump
      result = []
      @data.map { |k,v| "#{k}=#{v}\n" }.join
    end

    def load(payload)
      @data = @data.merge(_parse(payload))
    end

    private

    def _assert(condition, message)
      return if condition
      $stderr.puts message
      exit 1
    end

    def _parse(payload)
      Hash.new.tap do |result|
        payload.strip.split(/[\n\r]+/).each do |line|
          next if line.strip.empty? || line =~ /^#/
          _assert(line.strip =~ /^([^=]+)=(.*)$/, "Cannot parse '#{line}'")
          result[$1] = $2
        end
      end
    end
  end
end
