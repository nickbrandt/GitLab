# frozen_string_literal: true

module QA
  module EE
    module Resource
      module Settings
        class Elasticsearch < QA::Resource::Base
          attr_accessor :es_enabled
          attr_accessor :es_indexing
          attr_accessor :es_url

          def initialize
            @es_enabled = true
            @es_indexing = true
            @es_url = 'http://elastic68:9200'
          end

          def fabricate!
            QA::Page::Main::Menu.perform(&:click_admin_area)

            QA::Page::Admin::Menu.perform(&:go_to_elsticsearch_index)
            QA::EE::Page::Admin::Elasticsearch::Index.perform do
              es.check_indexing if @es_indexing
              es.enter_link(@es_url)
              es.click_submit
            end

            QA::Page::Admin::Menu.perform(&:go_to_elsticsearch_settings)
            QA::EE::Page::Admin::Elasticsearch::Settings.perform do
              es.check_search if @es_enabled
              es.click_submit
            end
          end

          def fabricate_via_api!
            @es_enabled ? api_post : resource_web_url(api_get)
          end

          def resource_web_url(resource)
            super
          rescue ResourceURLMissingError
            # this particular resource does not expose a web_url property
          end

          def api_get_path
            "/application/settings"
          end

          def api_post_path
            "/application/settings"
          end

          def api_post_body
            {
              elasticsearch_search: @es_enabled,
              elasticsearch_indexing: @es_indexing,
              elasticsearch_url: @es_url
            }
          end
        end
      end
    end
  end
end
