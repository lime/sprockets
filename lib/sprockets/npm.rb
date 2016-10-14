# frozen_string_literal: true
require 'json'

module Sprockets
  module Npm
    # Internal: Override resolve_alternates to install package.json behavior.
    #
    # load_path    - String environment path
    # logical_path - String path relative to base
    #
    # Returns candiate filenames.
    def resolve_alternates(load_path, logical_path)
      candidates, deps = super

      # package.json can only be nested one level deep
      if !logical_path.index('/'.freeze)
        dirname = File.join(load_path, logical_path)

        if directory?(dirname)
          filename = 'package.json'
          package_json_exist  = File.exist?(filename)

          if package_json_exist
            deps << build_file_digest_uri(filename)
            read_npm_main(dirname, filename) do |path|
              if file?(path)
                candidates << path
              end
            end
          end
        end
      end

      return candidates, deps
    end

    # Internal: Read package.json's main directive.
    #
    # dirname  - String path to component directory.
    # filename - String path to package.json.
    #
    # Returns nothing.
    def read_npm_main(dirname, filename)
      package = JSON.parse(File.read(filename), create_additions: false)

      case package['main']
      when String
        yield File.expand_path(package['main'], dirname)
      when Array
        package['main'].each do |name|
          yield File.expand_path(name, dirname)
        end
      end
    end
  end
end