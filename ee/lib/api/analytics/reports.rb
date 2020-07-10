# frozen_string_literal: true

module API
  module Analytics
    class Reports < Grape::API::Instance
      DESCRIPTION_DETAIL =
        'This feature is experimental and gated by the `:report_pages`'\
        ' feature flag, introduced in GitLab 13.2.'

      helpers do
        def api_endpoints_available?
          # This will be scoped to a project or a group
          Feature.enabled?(:report_pages) && ::License.feature_available?(:group_activity_analytics)
        end

        def load_report
          loader_class = Gitlab::Analytics::Reports::ConfigLoader
          report_id = params[:report_id]

          loader_class.new.find_report_by_id!(report_id)
        rescue loader_class::MissingReportError
          not_found!("Report(#{report_id})")
        end

        def report
          @report ||= load_report
        end
      end

      params do
        requires :report_id, type: String, desc: 'The ID of the report'
      end

      resource :analytics do
        resource :reports do
          route_param :report_id do
            resource :chart do
              get do
                not_found! unless api_endpoints_available?

                present report, with: EE::API::Entities::Analytics::Reports::Chart
              end
            end
          end
        end

        resource :series do
          params do
            requires :series_id, type: String, desc: 'The ID of the series'
          end
          route_param :report_id do
            route_param :series_id do
              get do
                not_found! unless api_endpoints_available?

                # Dummy response
                {
                  labels: %w[label1 label2 label3],
                  datasets: [
                    {
                      label: "Series 1",
                      data: [
                        1,
                        2,
                        3
                      ]
                    }
                  ]
                }
              end
            end
          end
        end
      end
    end
  end
end
