# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        module Overview
          module Groups
            module Edit
              def self.included(page)
                page.class_eval do
                  view 'ee/app/views/admin/_namespace_plan.html.haml' do
                    element :plan_dropdown
                  end
                end
              end

              def select_plan(plan)
                select_element(:plan_dropdown, plan)
              end
            end
          end
        end
      end
    end
  end
end
