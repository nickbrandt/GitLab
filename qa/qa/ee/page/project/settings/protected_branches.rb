# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          module ProtectedBranches
            def self.prepended(page)
              page.module_eval do
                view 'ee/app/views/projects/protected_branches/ee/_create_protected_branch.html.haml' do
                  element :allowed_to_push_select
                  element :allowed_to_push_dropdown
                  element :allowed_to_merge_select
                  element :allowed_to_merge_dropdown
                end

                view 'ee/app/views/projects/protected_branches/ee/_protected_branch_access_summary.html.haml' do
                  element :allowed_to_merge
                end
              end
            end

            private

            def select_allowed(action, allowed)
              click_element :"allowed_to_#{action}_select"

              allowed[:roles] = QA::Resource::ProtectedBranch::Roles::NO_ONE unless allowed.key?(:roles)

              within_element(:"allowed_to_#{action}_dropdown") do
                click_on allowed[:roles]
                allowed[:users].each { |user| click_on user.username } if allowed.key?(:users)
                allowed[:groups].each { |group| click_on group.name } if allowed.key?(:groups)
              end

              # Click the select element again to close the dropdown
              click_element :"allowed_to_#{action}_select"
            end
          end
        end
      end
    end
  end
end
