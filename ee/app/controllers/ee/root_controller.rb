# frozen_string_literal: true

module EE
  module RootController
    extend ::Gitlab::Utils::Override

    override :redirect_logged_user
    def redirect_logged_user
      case current_user.dashboard
      when 'operations'
        if current_user.can?(:read_operations_dashboard)
          return redirect_to(operations_path)
        end
      end

      super
    end
  end
end
