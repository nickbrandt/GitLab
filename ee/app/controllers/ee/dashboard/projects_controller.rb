# frozen_string_literal: true

module EE
  module Dashboard
    module ProjectsController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      private

      override :render_projects
      def render_projects
        if show_onboarding_welcome_page?
          redirect_to explore_onboarding_index_path
        else
          super
        end
      end

      def show_onboarding_welcome_page?
        return false unless ::Gitlab.com?
        return false if cookies['onboarding_dismissed'] == 'true'

        ::Feature.enabled?(:user_onboarding) && !show_projects?(projects, params)
      end
    end
  end
end
