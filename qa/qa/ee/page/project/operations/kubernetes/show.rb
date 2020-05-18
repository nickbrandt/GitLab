# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Operations
          module Kubernetes
            module Show
              extend QA::Page::PageConcern

              def self.prepended(base)
                super

                base.class_eval do
                  view 'ee/app/views/clusters/clusters/_health.html.haml' do
                    element :cluster_health_section
                  end

                  view 'ee/app/views/clusters/clusters/_health_tab.html.haml' do
                    element :health, required: true
                  end
                end
              end

              def wait_for_cluster_health
                wait_until(max_duration: 120, sleep_interval: 3, reload: true) do
                  has_cluster_health_graphs?
                end
              end

              def open_health
                has_element?(:health, wait: 30)
                click_element :health
              end

              def has_cluster_health_graphs?
                within_cluster_health_section do
                  has_text?('CPU Usage')
                end
              end

              def within_cluster_health_section
                within_element :cluster_health_section do
                  yield
                end
              end
            end
          end
        end
      end
    end
  end
end
