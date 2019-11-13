# frozen_string_literal: true

module Clusters
  module Aws
    class AuthorizeRoleService
      attr_reader :user

      Response = Struct.new(:status, :body)

      ERRORS = [
        ActiveRecord::RecordInvalid,
        Clusters::Aws::FetchCredentialsService::MissingRoleError,
        ::Aws::Errors::MissingCredentialsError,
        ::Aws::STS::Errors::ServiceError
      ].freeze

      def initialize(user, params:)
        @user = user
        @params = params
      end

      def execute
        @role = create_role!

        Response.new(:ok, credentials)
      rescue *ERRORS
        Response.new(:unprocessable_entity, {})
      end

      private

      attr_reader :role, :params

      def create_role!
        user.create_aws_role!(params)
      end

      def credentials
        Clusters::Aws::FetchCredentialsService.new(role).execute
      end
    end
  end
end
