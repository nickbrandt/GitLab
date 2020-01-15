# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Operations
          module Kubernetes
            module Show
              def self.prepended(page)
                page.module_eval do
                  view 'ee/app/views/projects/clusters/_prometheus_graphs.html.haml' do
                    element :cluster_health_section
                  end
                end
              end

              def wait_for_cluster_health
                wait_until(max_duration: 120, sleep_interval: 3, reload: true) do
                  has_cluster_health_graphs?
                end
              end

              def has_cluster_health_title?
                within_cluster_health_section do
                  has_text?('Cluster health')
                end
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
