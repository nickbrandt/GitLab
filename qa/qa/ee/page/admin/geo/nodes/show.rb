# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        module Geo
          module Nodes
            class Show < QA::Page::Base
              view 'ee/app/views/admin/geo/nodes/index.html.haml' do
                element :new_node_link
              end

              def new_node!
                click_element :new_node_link
              end
            end
          end
        end
      end
    end
  end
end
