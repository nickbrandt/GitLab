# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Yaml
        AVAILABLE_TAGS = [Config::Yaml::Tags::Reference].freeze

        class << self
          def load!(content, project: nil, file_location: '.gitlab-ci.yml')
            ensure_custom_tags

            # Gitlab::Config::Loader::Yaml.new(content, additional_permitted_classes: AVAILABLE_TAGS).load!
            # TODO: fix it
            External::Reader.new(file_location, content).read
          end

          private

          def ensure_custom_tags
            @ensure_custom_tags ||= begin
              AVAILABLE_TAGS.each { |klass| Psych.add_tag(klass.tag, klass) }

              true
            end
          end
        end
      end
    end
  end
end
