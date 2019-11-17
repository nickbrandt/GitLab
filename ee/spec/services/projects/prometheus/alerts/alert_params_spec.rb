# frozen_string_literal: true

require 'spec_helper'

describe Projects::Prometheus::Alerts::AlertParams do
  let(:service_class) do
    Class.new do
      include Projects::Prometheus::Alerts::AlertParams
      attr_accessor :params
      def initialize(params)
        @params = params
      end
    end
  end

  let_it_be(:project) { create(:project, name: 'project') }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:other_project) { create(:project, name: 'other_project') }
  let_it_be(:other_environment) { create(:environment, project: other_project) }

  let_it_be(:project_sum_metric) do
    create(:prometheus_metric, project: project, query: "sum(project)", legend: 'sum_project')
  end

  let_it_be(:project_avg_metric) do
    create(:prometheus_metric, project: project, query: 'avg(project)', legend: 'avg_project')
  end

  let_it_be(:other_sum_metric) do
    create(:prometheus_metric, project: other_project, query: "sum(other)", legend: 'sum_other')
  end

  let_it_be(:other_avg_metric) do
    create(:prometheus_metric, project: other_project, query: 'avg(other)', legend: 'avg_other')
  end

  let_it_be(:blank_sum_metric) do
    create(:prometheus_metric, project: nil, common: true, query: "sum(blank)", legend: 'sum_blank')
  end

  let_it_be(:blank_avg_metric) do
    create(:prometheus_metric, project: nil, common: true, query: 'avg(blank)', legend: 'avg_blank')
  end

  describe 'alert_params' do
    context 'converts legends' do
      it 'with a single metric legend' do
        params = { alert_query: +'(sum_project)', environment_id: environment.id }
        service_class.new(params).alert_params
        expect(params[:alert_query]).to match(/\(!#{project_sum_metric.id}\)/)
        expect(params[:prometheus_metric_id]).to eq(project_sum_metric.id)
      end

      it 'with invalid prometheus_metric_id' do
        params = {
          alert_query: +'(sum_project)',
          environment_id: environment.id,
          prometheus_metric_id: blank_sum_metric.id
        }
        service_class.new(params).alert_params
        expect(params[:alert_query]).to match(/\(!#{project_sum_metric.id}\)/)
        expect(params[:prometheus_metric_id]).to eq(project_sum_metric.id)
      end

      it 'with multiple metric legends' do
        params = { alert_query: +'(sum_project) / (avg_project)', environment_id: environment.id }
        service_class.new(params).alert_params
        expect(params[:alert_query]).to match(/\(!#{project_sum_metric.id}\)/)
        expect(params[:alert_query]).to match(/\(!#{project_avg_metric.id}\)/)
      end

      it 'with multiple metric legends and nil prometheus_metric_id' do
        params = {
          alert_query: +'(sum_project) (avg_project)',
          environment_id: environment.id,
          prometheus_metric_id: nil
        }
        service_class.new(params).alert_params
        expect(params[:alert_query]).to match(/\(!#{project_sum_metric.id}\)/)
        expect(params[:alert_query]).to match(/\(!#{project_avg_metric.id}\)/)
        expect(params[:prometheus_metric_id]).to eq(project_sum_metric.id)
      end

      it 'with multiple metric legends and valid prometheus_metric_id' do
        params = {
          alert_query: +'(sum_project) (avg_project)',
          environment_id: environment.id,
          prometheus_metric_id: project_avg_metric.id
        }
        service_class.new(params).alert_params
        expect(params[:alert_query]).to match(/\(!#{project_sum_metric.id}\)/)
        expect(params[:alert_query]).to match(/\(!#{project_avg_metric.id}\)/)
        expect(params[:prometheus_metric_id]).to eq(project_avg_metric.id)
      end

      it 'with a single invalid metric legend' do
        params = { alert_query: +'(sum_other)', environment_id: environment.id }
        service_class.new(params).alert_params
        expect(params[:alert_query]).to match(/\(sum_other\)/)
        expect(params[:prometheus_metric_id]).to eq(nil)
      end

      it 'with mixed invalid and valid metric legends' do
        params = { alert_query: +'(sum_other) * (sum_project)', environment_id: environment.id }
        service_class.new(params).alert_params
        expect(params[:alert_query]).to match(/\(sum_other\)/)
        expect(params[:alert_query]).to match(/\(!#{project_sum_metric.id}\)/)
        expect(params[:prometheus_metric_id]).to eq(project_sum_metric.id)
      end
    end
  end
end
