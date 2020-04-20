# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Operations
          module Metrics
            module Show
              EXPECTED_LABEL = 'Total (GB)'
              EXPECTED_TITLE_CUSTOM_METRIC = 'HTTP Requests (Total)'

              def self.prepended(page)
                page.module_eval do
                  view 'app/assets/javascripts/monitoring/components/alert_widget_form.vue' do
                    element :alert_query_dropdown
                    element :alert_query_option
                    element :alert_threshold_field
                  end

                  view 'app/assets/javascripts/monitoring/components/dashboard.vue' do
                    element :add_metric_button
                  end

                  view 'app/assets/javascripts/custom_metrics/components/custom_metrics_form_fields.vue' do
                    element :custom_metric_prometheus_title_field
                    element :custom_metric_prometheus_query_field
                    element :custom_metric_prometheus_y_label_field
                    element :custom_metric_prometheus_unit_label_field
                    element :custom_metric_prometheus_legend_label_field
                  end
                end
              end

              def wait_for_alert(operator = '>', threshold = 0)
                wait_until(reload: false) { has_alert?(operator, threshold) }
              end

              def has_alert?(operator = '>', threshold = 0)
                within_element :prometheus_graphs do
                  has_text?([EXPECTED_LABEL, operator, threshold].join(' '))
                end
              end

              def write_first_alert(operator = '>', threshold = 0)
                open_first_alert_modal
                click_on operator
                fill_element :alert_threshold_field, threshold

                within('.modal-content') { click_button(class: 'btn-success') }
              end

              def delete_first_alert
                open_first_alert_modal

                within('.modal-content') { click_button(class: 'btn-danger') }
                wait_for_requests
              end

              def open_first_alert_modal
                all_elements(:prometheus_widgets_dropdown, minimum: 1).first.click
                click_element :alert_widget_menu_item

                click_element :alert_query_dropdown unless has_element?(:alert_query_option, wait: 3)
                all_elements(:alert_query_option, minimum: 1).first.click
              end

              def add_custom_metric
                open_add_metric_modal

                fill_element :custom_metric_prometheus_title_field, EXPECTED_TITLE_CUSTOM_METRIC
                fill_element :custom_metric_prometheus_query_field, 'rate(http_requests_total[5m])'
                fill_element :custom_metric_prometheus_y_label_field, 'Requests/second'
                fill_element :custom_metric_prometheus_unit_label_field, 'req/sec'
                fill_element :custom_metric_prometheus_legend_label_field, 'HTTP requests'

                save_changes
              end

              def has_custom_metric?
                within_element :prometheus_graphs do
                  has_text?(EXPECTED_TITLE_CUSTOM_METRIC)
                end
              end

              private

              def open_add_metric_modal
                click_element :add_metric_button
              end

              def save_changes
                within('.modal-content') { click_button(class: 'btn-success') }
              end
            end
          end
        end
      end
    end
  end
end
