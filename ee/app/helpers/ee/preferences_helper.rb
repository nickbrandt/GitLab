# frozen_string_literal: true

module EE
  module PreferencesHelper
    extend ::Gitlab::Utils::Override

    override :excluded_dashboard_choices
    def excluded_dashboard_choices
      return [] if can?(current_user, :read_operations_dashboard)

      super
    end

    def group_view_choices
      choices = [
        [_('Details (default)'), :details]
      ]

      if License.feature_available?(:security_dashboard)
        choices << [_('Security dashboard'), :security_dashboard]
      end

      choices
    end
  end
end
