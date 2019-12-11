# frozen_string_literal: true

module EE
  module Types
    module ProjectType
      extend ActiveSupport::Concern

      prepended do
        field :service_desk_enabled, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if the project has service desk enabled.'

        field :service_desk_address, GraphQL::STRING_TYPE, null: true,
          description: 'E-mail address of the service desk.'
      end
    end
  end
end
