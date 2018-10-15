module QA
  module EE
    module Page
      module Admin
        class License < QA::Page::Base
          view 'ee/app/views/admin/licenses/missing.html.haml' do
            element :missing_license, 'You do not have a license' # rubocop:disable QA/ElementWithPattern
          end

          view 'ee/app/views/admin/licenses/show.html.haml' do
            element :license_upload_link, "link_to 'Upload New License'" # rubocop:disable QA/ElementWithPattern
          end

          view 'ee/app/views/admin/licenses/new.html.haml' do
            element :license_type, 'radio_button_tag :license_type' # rubocop:disable QA/ElementWithPattern
            element :license_type_placeholder, 'Enter license key' # rubocop:disable QA/ElementWithPattern
            element :license_key_field, 'text_area :data' # rubocop:disable QA/ElementWithPattern
            element :license_key_placeholder, 'label :data, "License key"' # rubocop:disable QA/ElementWithPattern
            element :license_upload_buttonm, "submit 'Upload license'" # rubocop:disable QA/ElementWithPattern
          end

          def no_license?
            page.has_content?('You do not have a license')
          end

          def add_new_license(key)
            raise 'License key empty!' if key.to_s.empty?

            click_link 'Upload New License'
            choose 'Enter license key'
            fill_in 'License key', with: key
            click_button 'Upload license'
          end
        end
      end
    end
  end
end
