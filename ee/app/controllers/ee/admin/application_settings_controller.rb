# frozen_string_literal: true

module EE
  module Admin
    module ApplicationSettingsController
      extend ::Gitlab::Utils::Override

      EE_VALID_SETTING_PANELS = %w(templates).freeze

      EE_VALID_SETTING_PANELS.each do |action|
        define_method(action) { perform_update if submitted? }
      end

      def visible_application_setting_attributes
        attrs = super

        if License.feature_available?(:repository_mirrors)
          attrs += EE::ApplicationSettingsHelper.repository_mirror_attributes
        end

        if License.feature_available?(:custom_project_templates)
          attrs << :custom_project_templates_group_id
        end

        if License.feature_available?(:email_additional_text)
          attrs << :email_additional_text
        end

        if License.feature_available?(:custom_file_templates)
          attrs << :file_template_project_id
        end

        if License.feature_available?(:pseudonymizer)
          attrs << :pseudonymizer_enabled
        end

        if License.feature_available?(:default_project_deletion_protection)
          attrs << :default_project_deletion_protection
        end

        if License.feature_available?(:required_ci_templates)
          attrs << :required_instance_ci_template
        end

        attrs
      end

      def geo_redirection
        redirect_to admin_geo_settings_url, notice: 'You were automatically redirected to <strong>Admin Area > Geo > Setting</strong><br /> '\
                                                    'From GitLab 12.7 on, this will be the only place for Geo settings and <strong>Admin Area > Settings > Geo</strong> will be removed.'.html_safe
      end

      private

      override :valid_setting_panels
      def valid_setting_panels
        super + EE_VALID_SETTING_PANELS
      end
    end
  end
end
