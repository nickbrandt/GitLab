# frozen_string_literal: true

module EE
  module IssuableBaseService
    private

    def filter_params(issuable)
      # This security check is repeated here to avoid multiple backports,
      # this should be refactored to be reused from the base class.
      ability_name = :"admin_#{issuable.to_ability_name}"

      unless issuable.supports_weight? && can?(current_user, ability_name, issuable)
        params.delete(:weight)
      end

      super
    end
  end
end
