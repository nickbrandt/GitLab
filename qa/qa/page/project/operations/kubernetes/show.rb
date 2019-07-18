# frozen_string_literal: true

module QA
  module Page
    module Project
      module Operations
        module Kubernetes
          class Show < Page::Base
            view 'app/assets/javascripts/clusters/components/application_row.vue' do
              element :application_row, 'js-cluster-application-row-${this.id}' # rubocop:disable QA/ElementWithPattern
              element :install_button, "__('Install')" # rubocop:disable QA/ElementWithPattern
              element :installed_button, "__('Installed')" # rubocop:disable QA/ElementWithPattern
            end

            view 'app/assets/javascripts/clusters/components/applications.vue' do
              element :ingress_ip_address, 'id="ingress-endpoint"' # rubocop:disable QA/ElementWithPattern
            end

            view 'app/views/clusters/clusters/_form.html.haml' do
              element :base_domain
              element :save_domain
            end

            view 'ee/app/views/projects/clusters/_prometheus_graphs.html.haml' do
              element :cluster_health_section
            end

            def install!(application_name)
              within(".js-cluster-application-row-#{application_name}") do
                page.has_button?('Install', wait: 30)
                click_on 'Install'
              end
            end

            def await_installed(application_name)
              within(".js-cluster-application-row-#{application_name}") do
                page.has_text?(/Installed|Uninstall/, wait: 300)
              end
            end

            def ingress_ip
              # We need to wait longer since it can take some time before the
              # ip address is assigned for the ingress controller
              page.find('#ingress-endpoint', wait: 1200).value
            end

            def set_domain(domain)
              fill_element :base_domain, domain
            end

            def save_domain
              click_element :save_domain
            end

            def wait_for_cluster_health
              wait(max: 120, interval: 3, reload: true) do
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
