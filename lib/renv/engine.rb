require 'renv'
require 'fog'
require 'renv/data'
require 'renv/connection'

module Renv
  class Engine
    def initialize(name: nil, connection:, data: nil)
      @_name      = name
      @connection = connection
      @_data      = data || Data.new
      @loaded     = false
    end

    def get(key)
      _data[key]
    end

    def set(hash)
      hash.each_pair do |key, value|
        _data[key] = value
      end
      _save
    end

    def del(keys)
      keys.each { |key| _data.delete(key) }
      _save
    end

    def dump
      _data.dump
    end

    def load(payload)
      _data.load(payload)
      _save
    end

    private

    def _data
      return @_data if @loaded
      s3file = @connection.files.get(_path_current)
      payload = s3file ? s3file.body : ''
      @loaded = true
      @_data.load(payload)
    end

    def _save
      [_path_new, _path_current].each do |path|
        @connection.files.create(key: path, body: _data.dump, public: false)
      end
    end

    def _path_current
      @_path_current ||= "#{_name}/current"
    end

    def _path_new
      @_path_new ||= "#{_name}/#{Time.now.strftime('%FT%T')}"
    end

    def _name
      @_name ||= @connection.app_name
    end

    def _app
      @connection.app
    end
    
  end
end
