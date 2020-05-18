# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          module CICD
            extend QA::Page::PageConcern

            def self.prepended(base)
              super

              base.class_eval do
                view 'ee/app/views/projects/settings/ci_cd/_managed_licenses.html.haml' do
                  element :license_compliance_settings_content
                end
              end
            end

            def expand_license_compliance(&block)
              expand_section(:license_compliance_settings_content) do
                Settings::LicenseCompliance.perform(&block)
              end
            end
          end
        end
      end
    end
  end
end
