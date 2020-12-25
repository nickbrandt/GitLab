# frozen_string_literal: true

require 'find'

module Gitlab
  module Graphql
    module Queries
      IMPORT_RE = /^#\s*import "(?<path>[^"]+)"$/m.freeze
      # TODO: validate both the EE and CE versions
      EE_ELSE_CE = /^ee_else_ce/.freeze
      HOME_RE = /^~/.freeze
      HOME_EE = %r{^ee/}.freeze
      DOTS_RE = %r{^(\.\./)+}.freeze
      DOT_RE = %r{^\./}.freeze
      IMPLICIT_ROOT = %r{^app/}.freeze
      CLIENT_DIRECTIVE = /@client/.freeze
      CONN_DIRECTIVE = /@connection\(key: "\w+"\)/.freeze

      class WrappedError
        delegate :message, to: :@error

        def initialize(error)
          @error = error
        end

        def path
          []
        end
      end

      class FileNotFound
        def initialize(file)
          @file = file
        end

        def message
          "File not found: #{@file}"
        end

        def path
          []
        end
      end

      class Definition
        attr_reader :file, :imports

        def initialize(path, fragments)
          @file = path
          @fragments = fragments
          @imports = []
          @errors = []
          @ee_else_ce = []
        end

        def text(ee = false)
          qs = [query] + all_imports(ee).uniq.sort.map { |p| fragment(p).query }
          qs.join("\n\n").gsub(/\n\n+/, "\n\n")
        end

        def query
          return @query if defined?(@query)

          # CONN_DIRECTIVEs are purely client-side constructs
          @query = File.read(file).gsub(CONN_DIRECTIVE, '').gsub(IMPORT_RE) do
            path = $~[:path]

            if EE_ELSE_CE.match?(path)
              @ee_else_ce << path.gsub(EE_ELSE_CE, '')
            else
              @imports << fragment_path(path)
            end

            ''
          end
        rescue Errno::ENOENT
          @errors << FileNotFound.new(file)
          @query = nil
        end

        def all_imports(ee = false)
          return [] if query.nil?

          home = ee ? @fragments.home_ee : @fragments.home
          eithers = @ee_else_ce.map { |p| home + p }

          (imports + eithers).flat_map { |p| [p] + @fragments.get(p).all_imports(ee) }
        end

        def all_errors
          return @errors.to_set if query.nil?

          paths = imports + @ee_else_ce.flat_map { |p| [@fragments.home + p, @fragments.home_ee + p] }

          paths.map { |p| fragment(p).all_errors }.reduce(@errors.to_set) { |a, b| a | b }
        end

        def fragment(path)
          @fragments.get(path)
        end

        def fragment_path(import_path)
          frag_path = import_path.gsub(HOME_RE, @fragments.home)
          frag_path = frag_path.gsub(HOME_EE, @fragments.home_ee + '/')
          frag_path = frag_path.gsub(DOT_RE) do
            Pathname.new(file).parent.to_s + '/'
          end
          frag_path = frag_path.gsub(DOTS_RE) do |dots|
            rel_dir(dots.split('/').count)
          end
          frag_path = frag_path.gsub(IMPLICIT_ROOT) do
            (Rails.root / 'app').to_s + '/'
          end

          frag_path
        end

        def rel_dir(n_steps_up)
          path = Pathname.new(file).parent
          while n_steps_up > 0
            path = path.parent
            n_steps_up -= 1
          end

          path.to_s + '/'
        end

        # TODO: move these warnings to the rake task
        def validate(schema)
          return [:client_query, []] if CLIENT_DIRECTIVE.match?(text)

          errs = all_errors.presence || schema.validate(text)
          if @ee_else_ce.present?
            errs += schema.validate(text(true))
          end

          [:validated, errs]
        rescue ::GraphQL::ParseError => e
          [:validated, [WrappedError.new(e)]]
        end
      end

      class Fragments
        def initialize(root, dir = 'app/assets/javascripts')
          @root = root
          @store = {}
          @dir = dir
        end

        def home
          @home ||= (@root / @dir).to_s
        end

        def home_ee
          @home_ee ||= (@root / 'ee' / @dir).to_s
        end

        def get(frag_path)
          @store[frag_path] ||= Definition.new(frag_path, self)
        end
      end

      def self.find(root)
        definitions = []

        ::Find.find(root.to_s) do |path|
          next unless path.ends_with?('.graphql')
          next if path.ends_with?('.fragment.graphql')
          next if path.ends_with?('typedefs.graphql')

          definitions << Definition.new(path, fragments)
        end

        definitions
      rescue Errno::ENOENT
        [] # root does not exist
      end

      def self.fragments
        @fragments ||= Fragments.new(Rails.root)
      end

      def self.all
        ['.', 'ee'].flat_map do |prefix|
          find(Rails.root / prefix / 'app/assets/javascripts')
        end
      end

      def self.known_failure?(path)
        @known_failures ||= YAML.safe_load(File.read(Rails.root.join('config', 'known_invalid_graphql_queries.yml')))

        @known_failures.fetch('filenames', []).any? { |known_failure| path.to_s.ends_with?(known_failure) }
      end
    end
  end
end
