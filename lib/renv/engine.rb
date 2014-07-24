require 'renv'
require 'fog'
require 'renv/data'

module Renv
  class Engine
    def initialize(app: nil, name: nil, bucket: nil)
      @_app    = app
      @_name   = name
      @_bucket = bucket
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
      @_data ||= begin
        s3file = _directory.files.get(_path_current)
        payload = s3file ? s3file.body : ''
        Data.new(payload)
      end
    end

    def _save
      [_path_new, _path_current].each do |path|
        _directory.files.create(key: path, body: _data.dump, public: false)
      end
    end

    def _path_current
      @_path_current ||= "#{_name}/current"
    end

    def _path_new
      @_path_new ||= "#{_name}/#{Time.now.strftime('%FT%T')}"
    end

    def _directory
      @_directory ||= _connection.directories.get(_bucket).tap do |dir|
        if dir.nil?
          $stderr.puts "Bucket '#{_bucket}' does not seem to exist"
          exit 1
        end
      end
    end
    
    def _connection
      @_connection ||= Fog::Storage.new(
        provider:              'AWS',
        aws_access_key_id:     ENV.fetch("RENV_AWS_KEY_#{_app}"),
        aws_secret_access_key: ENV.fetch("RENV_AWS_SECRET_#{_app}"),
        region:                ENV.fetch("RENV_AWS_REGION_#{_app}", 'eu-west-1')
      )
    end

    def _bucket
      @_bucket ||= ENV.fetch("RENV_BUCKET_#{_app}")
    end

    def _name
      @_name ||= _app
    end

    def _app
      @_app ||= ENV.fetch('RENV_APP')
    end
    
  end
end
