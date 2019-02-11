# frozen_string_literal: true

module QA
  module EE
    module Resource
      class Epic < QA::Resource::Base
        attr_accessor :title

        attribute :group do
          QA::Resource::Group.fabricate!
        end

        def fabricate!
          group.visit!

          QA::EE::Page::Group::Menu.perform(&:go_to_group_epics)

          QA::EE::Page::Group::Epic::Index.perform do |page|
            page.click_new_epic
            page.set_title(@title)
            page.create_new_epic
            page.wait(interval: 1) do
              page.has_text?(@title)
            end
          end
        end
      end
    end
  end
end
