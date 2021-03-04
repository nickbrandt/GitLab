# frozen_string_literal: true

module Mutations
  module UserCallouts
    class Create < ::Mutations::BaseMutation
      graphql_name 'UserCalloutCreate'

      argument :feature_name,
               GraphQL::STRING_TYPE,
               required: true,
               description: "The feature name you want to dismiss the callout for."

      field :user_callout, Types::UserCalloutType,
        null: false,
        description: 'The user callout dismissed.'

      def resolve(feature_name:)
        user_callout = current_user.find_or_initialize_callout(feature_name)

        user_callout.update(dismissed_at: Time.current) if user_callout.valid?
        errors = errors_on_object(user_callout)

        {
          user_callout: user_callout,
          errors: errors
        }
      end
    end
  end
end
