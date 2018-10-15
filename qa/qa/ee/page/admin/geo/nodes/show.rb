module QA
  module EE
    module Page
      module Admin
        module Geo
          module Nodes
            class Show < QA::Page::Base
              view 'ee/app/views/admin/geo/nodes/index.html.haml' do
                element :new_node_link, /link_to .*New node/ # rubocop:disable QA/ElementWithPattern
              end

              def new_node!
                click_link 'New node'
              end
            end
          end
        end
      end
    end
  end
end
