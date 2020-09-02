# frozen_string_literal: true

module QA
  module EE
    module Resource
      class GroupIteration < QA::Resource::Base
        include Support::Dates

        attr_accessor :title

        attribute :group do
          QA::Resource::Group.fabricate_via_api!
        end

        attribute :id
        attribute :start_date
        attribute :due_date
        attribute :description
        attribute :title

        def initialize
          @start_date = current_date_yyyy_mm_dd
          @due_date = next_month_yyyy_mm_dd
          @title = "Iteration-#{SecureRandom.hex(8)}"
          @description = "This is a test iteration."
        end

        def fabricate!
          group.visit!

          QA::Page::Group::Menu.perform(&:go_to_group_iterations)

          QA::EE::Page::Group::Iteration::Index.perform(&:click_new_iteration_button)

          QA::EE::Page::Group::Iteration::New.perform do |new|
            new.fill_title(@title)
            new.fill_description(@description)
            new.fill_start_date(@start_date)
            new.fill_due_date(@due_date)
            new.click_create_iteration_button
          end
        end
      end
    end
  end
end
