# frozen_string_literal: true

module EE
  module Projects
    module Prometheus
      module MetricsController
        extend ActiveSupport::Concern

        prepended do
          before_action :check_custom_metrics_license!,
            only: [:validate_query, :index, :create, :update, :edit, :destroy]
        end

        def validate_query
          respond_to do |format|
            format.json do
              result = prometheus_adapter.query(:validate, params[:query])

              if result
                render json: result
              else
                head :accepted
              end
            end
          end
        end

        def new
          @metric = project.prometheus_metrics.new # rubocop:disable Gitlab/ModuleWithInstanceVariables
        end

        def index
          respond_to do |format|
            format.json do
              metrics = ::PrometheusMetricsFinder.new(
                project: project,
                ordered: true
              ).execute.to_a

              response = {}
              if metrics.any?
                response[:metrics] = ::PrometheusMetricSerializer
                                       .new(project: project)
                                       .represent(metrics)
              end

              render json: response
            end
          end
        end

        def create
          @metric = project.prometheus_metrics.create( # rubocop:disable Gitlab/ModuleWithInstanceVariables
            metrics_params.to_h.symbolize_keys
          )

          if @metric.persisted? # rubocop:disable Gitlab/ModuleWithInstanceVariables
            redirect_to edit_project_service_path(project, ::PrometheusService),
                        notice: _('Metric was successfully added.')
          else
            render 'new'
          end
        end

        def update
          @metric = update_metrics_service(prometheus_metric).execute # rubocop:disable Gitlab/ModuleWithInstanceVariables

          if @metric.persisted? # rubocop:disable Gitlab/ModuleWithInstanceVariables
            redirect_to edit_project_service_path(project, ::PrometheusService),
                        notice: _('Metric was successfully updated.')
          else
            render 'edit'
          end
        end

        def edit
          @metric = prometheus_metric # rubocop:disable Gitlab/ModuleWithInstanceVariables
        end

        def destroy
          destroy_metrics_service(prometheus_metric).execute

          respond_to do |format|
            format.html do
              redirect_to edit_project_service_path(project, ::PrometheusService), status: :see_other
            end
            format.json do
              head :ok
            end
          end
        end

        private

        def check_custom_metrics_license!
          render_404 unless project.feature_available?(:custom_prometheus_metrics)
        end

        def prometheus_metric
          @prometheus_metric ||= ::PrometheusMetricsFinder.new(id: params[:id]).execute.first
        end

        def update_metrics_service(metric)
          ::Projects::Prometheus::Metrics::UpdateService.new(metric, metrics_params)
        end

        def destroy_metrics_service(metric)
          ::Projects::Prometheus::Metrics::DestroyService.new(metric)
        end

        def metrics_params
          params.require(:prometheus_metric).permit(:title, :query, :y_label, :unit, :legend, :group)
        end
      end
    end
  end
end
