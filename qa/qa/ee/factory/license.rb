module QA
  module EE
    module Factory
      class License < QA::Factory::Base
        def fabricate!(license)
          QA::Page::Main::Login.perform(&:sign_in_using_admin_credentials)
          QA::Page::Main::Menu.perform(&:go_to_admin_area)
          QA::Page::Admin::Menu.perform(&:go_to_license)

          EE::Page::Admin::License.perform do |page|
            page.add_new_license(license) unless page.license?
          end

          QA::Page::Main::Menu.perform(&:sign_out)
        end
      end
    end
  end
end
