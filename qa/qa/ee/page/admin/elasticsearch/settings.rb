# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        module Elasticsearch
          class Settings < QA::Page::Base
            view 'ee/app/views/admin/elasticsearch/settings.html.haml' do
              element :search_checkbox
              element :submit_button
            end

            def check_search
              check_element :search_checkbox
            end

            def click_submit
              click_element :submit_button
            end
          end
        end
      end
    end
  end
end
