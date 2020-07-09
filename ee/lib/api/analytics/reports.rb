# frozen_string_literal: true

module API
  module Analytics
    class Reports < Grape::API::Instance
      DESCRIPTION_DETAIL =
        'This feature is experimental and gated by the `:report_pages`'\
        ' feature flag, introduced in GitLab 13.2.'

      helpers do
        def api_endpoints_available?
          Feature.enabled?(:report_pages, parent_entity) && parent_entity.feature_available?(:group_activity_analytics)
        end

        def load_report
          Gitlab::Analytics::Reports::ConfigLoader.find_report_by_id!(params[:report_id])
        rescue Gitlab::Analytics::Reports::ConfigLoader::MissingReportError
          not_found!("Report(#{params[:report_id]})")
        end

        def load_series
          Gitlab::Analytics::Reports::ConfigLoader.find_series_by_id!(params[:report_id], params[:series_id])

        rescue Gitlab::Analytics::Reports::ConfigLoader::MissingSeriesError
          not_found!("Series(#{params[:series_id]})")
        rescue Gitlab::Analytics::Reports::ConfigLoader::MissingReportError
          not_found!("Report(#{params[:report_id]})")
        end

        def load_parent_entity
          Group.find(params[:group_id])
        end

        def parent_entity
          @parent_entity ||= load_parent_entity
        end

        def report
          @report ||= load_report
        end

        def series
          @series ||= load_series
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

                data = Gitlab::Analytics::Reports::SeriesDataLoader.new(
                  series: series,
                  params: { parent: parent_entity, current_user: current_user }
                ).execute

                present series, with: EE::API::Entities::Analytics::Reports::Series, data: data
              end
            end
          end
        end
      end
    end
  end
end
