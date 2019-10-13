# frozen_string_literal: true

module EE
  module Gitlab
    module Scim
      class ParamsParser
        FILTER_OPERATORS = %w[eq].freeze
        OPERATIONS_OPERATORS = %w[Replace Add].freeze

        ATTRIBUTE_MAP = {
          id: :extern_uid,
          displayName: :name,
          'name.formatted': :name,
          'emails[type eq "work"].value': :email,
          active: :active,
          externalId: :extern_uid,
          userName: :username
        }.with_indifferent_access.freeze

        COERCED_VALUES = {
          'True' => true,
          'False' => false
        }.freeze

        def initialize(params)
          @params = params.with_indifferent_access
          @hash = {}
        end

        def deprovision_user?
          result[:active] == false
        end

        def result
          @result ||= process
        end

        private

        def process
          if @params[:filter]
            process_filter
          elsif @params[:Operations]
            process_operations
          else
            # SCIM POST params
            process_params
          end
        end

        def process_filter
          attribute, operator, value = @params[:filter].split(' ')

          return {} unless FILTER_OPERATORS.include?(operator)
          return {} unless ATTRIBUTE_MAP[attribute]

          { ATTRIBUTE_MAP[attribute] => coerce(value) }
        end

        def process_operations
          @params[:Operations].each_with_object({}) do |operation, hash|
            next unless OPERATIONS_OPERATORS.include?(operation[:op])

            attribute = ATTRIBUTE_MAP[operation[:path]]

            hash[attribute] = coerce(operation[:value]) if attribute
          end
        end

        def process_params
          overwrites = { email: parse_emails, name: parse_name }.compact
          parse_params.merge(overwrites)
        end

        def parse_params
          # compact can remove :active if the value for that is nil
          @params.except(:email, :name).compact.each_with_object({}) do |(param, value), hash|
            attribute = ATTRIBUTE_MAP[param]

            hash[attribute] = coerce(value) if attribute
          end
        end

        def parse_emails
          emails = @params[:emails]

          return unless emails

          email = emails.find { |email| email[:type] == 'work' || email[:primary] }
          email[:value] if email
        end

        def parse_name
          name = @params.delete(:name)

          return unless name

          formatted_name = name[:formatted]&.presence
          formatted_name ||= [name[:givenName], name[:familyName]].compact.join(' ')
          @hash[:name] = formatted_name
        end

        def coerce(value)
          return value unless value.is_a?(String)

          value = value.delete('\"')
          coerced = COERCED_VALUES[value]

          coerced.nil? ? value : coerced
        end
      end
    end
  end
end
