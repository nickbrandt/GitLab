# frozen_string_literal: true

module Gitlab
  module Auth
    module GroupSaml
      class DynamicSettings
        include Enumerable

        delegate :each, :keys, :[], to: :to_h

        def initialize(group)
          @group = group
        end

        def to_h
          return {} unless @group

          configured_settings || default_settings
        end

        private

        def configured_settings
          @configured_settings ||= @group.saml_provider&.settings
        end

        def default_settings
          @default_settings ||= SamlProvider::DefaultOptions.new(@group.full_path).to_h
        end
      end
    end
  end
end
