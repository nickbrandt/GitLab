# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        module Geo
          module Nodes
            class Show < QA::Page::Base
              view 'ee/app/assets/javascripts/geo_nodes_beta/components/app.vue' do
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
