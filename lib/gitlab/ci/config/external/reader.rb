# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Reader
          def initialize(filepath, content)
            @filepath = filepath
            @content = content
          end

          def read
            @result = parse_file

            raise Gitlab::Config::Loader::Yaml::DataTooLargeError, 'The parsed YAML is too big' if too_big?
            raise Gitlab::Config::Loader::Yaml::NotHashError, 'Invalid configuration format' unless hash?

            @result.deep_symbolize_keys!
          end

          private

          def parse_file
            file_content = Psych.parse(@content, filename: @filepath)
            class_loader = Psych::ClassLoader::Restricted.new(['Symbol'], [])
            scanner = Psych::ScalarScanner.new class_loader

            visitor = Reader::TrackedToRuby.new scanner, class_loader
            visitor.location_filename = @filepath
            visitor.accept(file_content)
          rescue Psych::Exception => e
            raise Gitlab::Config::Loader::FormatError, e.message
          end

          def hash?
            @result.is_a?(Hash)
          end

          def too_big?
            return false unless Feature.enabled?(:ci_yaml_limit_size, default_enabled: true)

            !deep_size.valid?
          end

          def deep_size
            Gitlab::Utils::DeepSize.new(@result, max_size: Gitlab::Config::Loader::Yaml::MAX_YAML_SIZE,
                                                 max_depth: Gitlab::Config::Loader::Yaml::MAX_YAML_DEPTH)
          end
        end
      end
    end
  end
end
