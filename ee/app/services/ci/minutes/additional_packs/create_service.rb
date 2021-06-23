# frozen_string_literal: true

module Ci
  module Minutes
    module AdditionalPacks
      class CreateService < ::Ci::Minutes::AdditionalPacks::BaseService
        def initialize(current_user, namespace, params = {})
          @current_user = current_user
          @namespace = namespace
          @purchase_xid = params[:purchase_xid]
          @expires_at = params[:expires_at]
          @number_of_minutes = params[:number_of_minutes]
        end

        def execute
          authorize_current_user!

          return successful_response if additional_pack.persisted?

          save_additional_pack ? successful_response : error_response
        end

        private

        attr_reader :current_user, :namespace, :purchase_xid, :expires_at, :number_of_minutes

        # rubocop: disable Cop/UserAdmin
        def authorize_current_user!
          # Using #admin? is discouraged as it will bypass admin mode authorisation checks,
          # however those checks are not in place in our REST API yet, and this service is only
          # going to be used by the API for admin-only actions
          raise Gitlab::Access::AccessDeniedError unless current_user&.admin?
        end
        # rubocop: enable Cop/UserAdmin

        # rubocop: disable CodeReuse/ActiveRecord
        def additional_pack
          @additional_pack ||= Ci::Minutes::AdditionalPack.find_or_initialize_by(
            namespace: namespace,
            purchase_xid: purchase_xid
          )
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def save_additional_pack
          additional_pack.assign_attributes(
            expires_at: expires_at,
            number_of_minutes: number_of_minutes
          )

          additional_pack.save
        end

        def successful_response
          success({ additional_pack: additional_pack })
        end

        def error_response
          error('Unable to save additional pack')
        end
      end
    end
  end
end
