# frozen_string_literal: true

module QA
  module EE
    module Resource
      module Geo
        class Node < QA::Resource::Base
          attr_accessor :address

          def fabricate!
            QA::Page::Main::Login.perform(&:sign_in_using_credentials)
            QA::Page::Main::Menu.perform(&:go_to_admin_area)
            QA::Page::Admin::Menu.perform(&:go_to_geo_nodes)
            EE::Page::Admin::Geo::Nodes::Show.perform(&:new_node!)

            EE::Page::Admin::Geo::Nodes::New.perform do |page|
              raise ArgumentError if @address.nil?

              page.set_node_address(@address)
              page.add_node!
            end

            QA::Page::Main::Menu.perform(&:sign_out)
          end
        end
      end
    end
  end
end
