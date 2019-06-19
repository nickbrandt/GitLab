# frozen_string_literal: true

module EE
  module IssuableActions
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    EE_PERMITTED_KEYS = %w[
      weight
    ].freeze

    override :authorize_admin_issuable!
    def authorize_admin_issuable!
      return access_denied! unless can?(current_user, :"admin_#{resource_name}", parent)
    end

    override :permitted_keys
    def permitted_keys
      @permitted_keys ||= (super + EE_PERMITTED_KEYS).freeze
    end
  end
end
