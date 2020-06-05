# frozen_string_literal: true

module EE
  module IssuableActions
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    EE_PERMITTED_KEYS = %w[
      weight
    ].freeze

    private

    override :bulk_update_permitted_keys
    def bulk_update_permitted_keys
      @permitted_keys ||= (super + EE_PERMITTED_KEYS).freeze
    end
  end
end
