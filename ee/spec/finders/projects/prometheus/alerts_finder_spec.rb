# frozen_string_literal: true

require 'spec_helper'

describe Projects::Prometheus::AlertsFinder do
  let(:finder) { described_class.new(params) }
  let(:params) { {} }

  describe 'with params' do
    let_it_be(:project) { create(:project) }
    let_it_be(:other_project) { create(:project) }
    let_it_be(:other_env) { create(:environment, project: other_project) }
    let_it_be(:production) { create(:environment, project: project) }
    let_it_be(:staging) { create(:environment, project: project) }
    let_it_be(:alert) { create_alert(project, production) }
    let_it_be(:alert2) { create_alert(project, production) }
    let_it_be(:stg_alert) { create_alert(project, staging) }
    let_it_be(:other_alert) { create_alert(other_project, other_env) }

    describe '#execute' do
      subject { finder.execute }

      context 'with project' do
        before do
          params[:project] = project
        end

        it { is_expected.to eq([alert, alert2, stg_alert]) }

        context 'with matching metric' do
          before do
            params[:metric] = alert.prometheus_metric
          end

          it { is_expected.to eq([alert]) }
        end

        context 'with matching metric id' do
          before do
            params[:metric] = alert.prometheus_metric_id
          end

          it { is_expected.to eq([alert]) }
        end

        context 'with project non-specific metric' do
          before do
            params[:metric] = other_alert.prometheus_metric
          end

          it { is_expected.to be_empty }
        end
      end

      context 'with environment' do
        before do
          params[:environment] = production
        end

        it { is_expected.to eq([alert, alert2]) }

        context 'with matching metric' do
          before do
            params[:metric] = alert.prometheus_metric
          end

          it { is_expected.to eq([alert]) }
        end

        context 'with environment non-specific metric' do
          before do
            params[:metric] = stg_alert.prometheus_metric
          end

          it { is_expected.to be_empty }
        end
      end

      context 'with matching project and environment' do
        before do
          params[:project] = project
          params[:environment] = production
        end

        it { is_expected.to eq([alert, alert2]) }

        context 'with matching metric' do
          before do
            params[:metric] = alert.prometheus_metric
          end

          it { is_expected.to eq([alert]) }
        end

        context 'with environment non-specific metric' do
          before do
            params[:metric] = stg_alert.prometheus_metric
          end

          it { is_expected.to be_empty }
        end
      end

      context 'with non-matching project-environment pair' do
        before do
          params[:project] = project
          params[:environment] = other_env
        end

        it { is_expected.to be_empty }
      end
    end

    private

    def create_alert(project, environment)
      create(:prometheus_alert, project: project, environment: environment)
    end
  end

  describe 'without params' do
    subject { finder }

    it 'raises an error' do
      expect { subject }
        .to raise_error(ArgumentError, 'Please provide either :project or :environment, or both')
    end
  end
end
