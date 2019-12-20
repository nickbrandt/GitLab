# frozen_string_literal: true

module EE
  module API
    module Settings
      extend ActiveSupport::Concern

      prepended do
        helpers do
          extend ::Gitlab::Utils::Override

          override :filter_attributes_using_license
          def filter_attributes_using_license(attrs)
            unless ::License.feature_available?(:repository_mirrors)
              attrs = attrs.except(*::EE::ApplicationSettingsHelper.repository_mirror_attributes)
            end

            unless ::License.feature_available?(:email_additional_text)
              attrs = attrs.except(:email_additional_text)
            end

            unless ::License.feature_available?(:custom_file_templates)
              attrs = attrs.except(:file_template_project_id)
            end

            unless ::License.feature_available?(:default_project_deletion_protection)
              attrs = attrs.except(:default_project_deletion_protection)
            end

            unless License.feature_available?(:marking_project_for_deletion)
              attrs = attrs.except(:deletion_adjourned_period)
            end

            attrs
          end
        end
      end
    end
  end
end
