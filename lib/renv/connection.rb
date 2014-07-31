require 'fog'
require 'delegate'
require 'renv'

module Renv
  class Connection < SimpleDelegator

    def initialize(app: nil, bucket: bucket)
      @_app     = app
      @_bucket  = bucket

      connection = Fog::Storage.new(
        provider:              'AWS',
        aws_access_key_id:     ENV.fetch("RENV_AWS_KEY_#{_app}"),
        aws_secret_access_key: ENV.fetch("RENV_AWS_SECRET_#{_app}"),
        region:                ENV.fetch("RENV_AWS_REGION_#{_app}", 'eu-west-1')
      )

      if connection.nil?
        $stderr.puts "Failed to connect to AWS, please check your key and secret."
        exit 1
      end

      bucket = connection.directories.get(_bucket).tap do |b|
        if b.nil?
          $stderr.puts "Bucket '#{_bucket}' does not seem to exist"
          exit 1
        end
      end

      super bucket

    rescue Excon::Errors::Forbidden
      $stderr.puts "Credentials rejected by AWS, please check your settings."
      exit 1
    end

    
    def app_name ; _app ; end

    private

    def _app
      @_app ||= ENV.fetch('RENV_APP')
    end

    def _bucket
      @_bucket ||= ENV.fetch("RENV_BUCKET_#{_app}")
    end

  end
end

