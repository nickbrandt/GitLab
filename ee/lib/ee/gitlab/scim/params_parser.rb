# frozen_string_literal: true

module EE
  module Gitlab
    module Scim
      class ParamsParser
        FILTER_OPERATORS = %w[eq]
        OPERATIONS_OPERATORS = %w[Replace Add]
        ATTRIBUTE_MAP = {
          id: :extern_uid,
          'name.formatted': :name,
          'emails[type eq "work".value': :mail
        }.with_indifferent_access

        def initialize(params)
          @filter = params[:filter]
          @operations = params[:operations]
          @hash = {}
        end

        def to_hash
          process_filter
          process_operations

          @hash
        end

        private

        def process_filter
          return unless @filter

          attribute, operator, value = @filter.split

          return unless FILTER_OPERATORS.include?(operator)
          return unless ATTRIBUTE_MAP[attribute]

          @hash[ATTRIBUTE_MAP[attribute]] = value.tr('\"', '')
        end

        def process_operations
          return unless @operations

          @operations.each do |operation|
            next unless OPERATIONS_OPERATORS.contains?(operation[:op])

            attribute = ATTRIBUTE_MAP[operation[:path]]

            @hash[attribute] = operation[:value] if attribute
          end
        end
      end
    end
  end
end
