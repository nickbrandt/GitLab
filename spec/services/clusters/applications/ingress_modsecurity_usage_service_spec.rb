# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::IngressModsecurityUsageService do
  describe '#execute' do
    ADO_MODSEC_KEY = Clusters::Applications::IngressModsecurityUsageService::ADO_MODSEC_KEY

    let(:project_with_ci_var) { create(:environment).project }
    let(:project_with_pipeline_var) { create(:environment).project }

    let(:deployment) do
      create(
        :deployment,
        environment: project_with_pipeline_var.environments.first,
        project: project_with_pipeline_var
      )
    end
    let(:pipeline) { deployment.deployable.pipeline }

    subject { described_class.new.execute }

    context 'mixed data' do
      let!(:ci_variable) { create(:ci_variable, project: project_with_ci_var, key: ADO_MODSEC_KEY, value: "On") }
      let!(:pipeline_variable) { create(:ci_pipeline_variable, pipeline: pipeline, key: ADO_MODSEC_KEY, value: "Off") }

      it 'gathers variable data' do
        expect(subject[:ingress_modsecurity_blocking]).to eq(1)
        expect(subject[:ingress_modsecurity_disabled]).to eq(1)
      end
    end

    context 'blocking' do
      let(:modsec_values) { { key: ADO_MODSEC_KEY, value: "On" } }

      let!(:ci_variable) { create(:ci_variable, project: project_with_ci_var, **modsec_values) }
      let!(:pipeline_variable) { create(:ci_pipeline_variable, pipeline: pipeline, **modsec_values) }

      it 'gathers variable data' do
        expect(subject[:ingress_modsecurity_blocking]).to eq(2)
        expect(subject[:ingress_modsecurity_disabled]).to eq(0)
      end
    end

    context 'disabled' do
      let(:modsec_values) { { key: ADO_MODSEC_KEY, value: "Off" } }

      let!(:ci_variable) { create(:ci_variable, project: project_with_ci_var, **modsec_values) }
      let!(:pipeline_variable) { create(:ci_pipeline_variable, pipeline: pipeline, **modsec_values) }

      it 'gathers variable data' do
        expect(subject[:ingress_modsecurity_blocking]).to eq(0)
        expect(subject[:ingress_modsecurity_disabled]).to eq(2)
      end
    end

    context 'when set as both ci and pipeline variables' do
      let(:modsec_values) { { key: ADO_MODSEC_KEY, value: "Off" } }

      let(:pipeline) { create(:ci_pipeline, :with_job, project: project_with_ci_var) }
      let!(:deployment) do
        create(
          :deployment,
          environment: project_with_ci_var.environments.first,
          project: project_with_ci_var,
          deployable: pipeline.builds.first
        )
      end

      let!(:ci_variable) { create(:ci_variable, project: project_with_ci_var, **modsec_values) }
      let!(:pipeline_variable) { create(:ci_pipeline_variable, pipeline: pipeline, **modsec_values) }

      it 'wont double-count projects' do
        expect(subject[:ingress_modsecurity_blocking]).to eq(0)
        expect(subject[:ingress_modsecurity_disabled]).to eq(1)
      end

      it 'gives precedence to pipeline variable' do
        pipeline_variable.update(value: "On")

        expect(subject[:ingress_modsecurity_blocking]).to eq(1)
        expect(subject[:ingress_modsecurity_disabled]).to eq(0)
      end
    end
  end
end
