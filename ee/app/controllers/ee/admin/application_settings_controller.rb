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

        if License.feature_available?(:adjourned_deletion_for_projects_and_groups)
          attrs << :deletion_adjourned_period
        end

        if License.feature_available?(:required_ci_templates)
          attrs << :required_instance_ci_template
        end

        if License.feature_available?(:disable_name_update_for_users)
          attrs << :updating_name_disabled_for_users
        end

        if License.feature_available?(:admin_merge_request_approvers_rules)
          attrs += EE::ApplicationSettingsHelper.merge_request_appovers_rules_attributes
        end

        if License.feature_available?(:packages)
          attrs << :npm_package_requests_forwarding
        end

        attrs
      end

      def geo_redirection
        redirect_to admin_geo_settings_url, notice: 'You were automatically redirected to <strong>Admin Area > Geo > Settings</strong><br /> '\
                                                    'From GitLab 13.0 on, this will be the only place for Geo settings and <strong>Admin Area > Settings > Geo</strong> will be removed.'.html_safe
      end

      def seat_link_payload
        data = ::Gitlab::SeatLinkData.new

        respond_to do |format|
          format.html do
            seat_link_json = JSON.pretty_generate(data)

            render html: ::Gitlab::Highlight.highlight('payload.json', seat_link_json, language: 'json')
          end
          format.json { render json: data.to_json }
        end
      end

      private

      override :valid_setting_panels
      def valid_setting_panels
        super + EE_VALID_SETTING_PANELS
      end
    end
  end
end
