# frozen_string_literal: true

module EE
  module Dashboard
    module ProjectsController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override
      include ::OnboardingExperimentHelper

      private

      override :render_projects
      def render_projects
        return redirect_to explore_onboarding_index_path if show_onboarding_welcome_page?

        super
      end

      override :preload_associations
      def preload_associations(projects)
        super.with_compliance_framework_settings
      end

      def show_onboarding_welcome_page?
        return false if onboarding_cookie_set?
        return false unless allow_access_to_onboarding?

        !show_projects?(projects, params)
      end

      def onboarding_cookie_set?
        cookies['onboarding_dismissed'] == 'true'
      end
    end
  end
end
