require 'renv'
require 'thor'
require 'renv/engine'

module Renv
  class CLI < Thor
    class_option :app,     aliases: '-a', desc: 'Application name, defaults to RENV_APP'
    class_option :bucket,  aliases: '-b', desc: 'S3 bucket storing environment(s), defaults to RENV_BUCKET_<app>'
    class_option :name,    aliases: '-n', desc: 'Environment name, e.g. for staging apps, defaults to app name'

    desc 'get KEY', 'returns the value of KEY'
    def get(key)
      puts _engine.get(key)
    end

    desc 'set KEY=VALUE...', 'sets the value of KEY to VALUE'
    def set(*pairs)
      hash = _parse_pairs(pairs)
      _engine.set(hash)
    end

    desc 'del KEY...', 'deletes KEY and its value'
    def del(*keys)
      _engine.del(keys)
    end

    desc 'dump', 'dumps all key-value pairs in .env format'
    def dump
      puts _engine.dump
    end

    desc 'load', 'set keys from standard input in .env format'
    def load
      _engine.load(STDIN.read)
    end

    private

    def _engine
      Engine.new(
        app:    options[:app],
        name:   options[:name]
        bucket: options[:bucket])
    end

    def _parse_pairs(pairs)
      Hash.new.tap do |h|
        pairs.each do |p|
          if p !~ /^([^=]+)=(.*)$/
            $stderr.puts "Not a valid key-value: '#{p}'"
            exit 1
          end
          h[$1] = $2
        end
      end
    end
  end
end

