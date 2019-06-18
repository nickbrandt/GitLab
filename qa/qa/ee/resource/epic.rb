# frozen_string_literal: true

module QA
  module EE
    module Resource
      class Epic < QA::Resource::Base
        attr_accessor :title

        attribute :group do
          QA::Resource::Group.fabricate!
        end

        attribute :id

        def fabricate!
          group.visit!

          QA::EE::Page::Group::Menu.perform(&:click_group_epics_link)

          QA::EE::Page::Group::Epic::Index.perform do |page|
            page.click_new_epic
            page.set_title(@title)
            page.create_new_epic
            page.wait(interval: 1) do
              page.has_text?(@title)
            end
          end
        end

        def resource_web_url(resource)
          super
        rescue ResourceURLMissingError
          # this particular resource does not expose a web_url property
        end

        def api_get_path
          "/groups/#{group}/epics/#{id}"
        end

        def api_post_path
          "/groups/#{group}/epics"
        end

        def api_post_body
          {
            title: title
          }
        end
      end
    end
  end
end
