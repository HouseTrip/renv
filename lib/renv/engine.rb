require 'renv'
require 'fog'
require 'renv/data'
require 'renv/connection'

module Renv
  class Engine
    def initialize(connection:, name: nil, data: nil)
      @_name       = name
      @_connection = connection
      @_data       = data || Data.new
      @_loaded     = false
    end

    def get(key)
      _data[key]
    end

    # Sets one or more key-value pairs
    def set(hash)
      hash.each_pair do |key, value|
        _data[key] = value
      end
      _save
    end

    # Deletes one or more keys-value pairs
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
      return @_data if @_loaded
      s3file = @_connection.files.get(_path_current)
      payload = s3file ? s3file.body : ''
      @_loaded = true
      @_data.load(payload)
    end

    def _save
      [_path_new, _path_current].each do |path|
        @_connection.files.create(key: path, body: _data.dump, public: false)
      end
    end

    def _path_current
      @_path_current ||= "#{_name}/current"
    end

    # "Backup" path, which is a timestamp in ISO format (2014-08-07T11:24:25)
    def _path_new
      @_path_new ||= "#{_name}/#{Time.now.strftime('%FT%T')}"
    end

    def _name
      @_name ||= @_connection.app_name
    end

    def _app
      @_connection.app
    end
    
  end
end
