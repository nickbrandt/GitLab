# frozen_string_literal: true

module EE
  module Gitlab
    module Scim
      class AttributeTransform
        MAPPINGS = {
          id: :extern_uid,
          displayName: :name,
          'name.formatted': :name,
          'emails[type eq "work"].value': :email,
          active: :active,
          externalId: :extern_uid,
          userName: :username
        }.with_indifferent_access.freeze

        def initialize(key)
          @key = key
        end

        def valid?
          MAPPINGS.key?(@key)
        end

        def gitlab_key
          MAPPINGS[@key]
        end

        def map_to(input)
          return {} unless valid?

          { gitlab_key => ValueParser.new(input).type_cast }
        end
      end
    end
  end
end
