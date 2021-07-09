# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Pipeline::Chain::Config::Content do
  let(:ci_config_path) { nil }
  let(:pipeline) { build(:ci_pipeline, project: project) }
  let(:content) { nil }
  let(:source) { :push }
  let(:command) { Gitlab::Ci::Pipeline::Chain::Command.new(project: project, content: content, source: source) }
  let(:content_result) do
    <<~EOY
    ---
    include:
    - project: compliance/hippa
      file: ".compliance-gitlab-ci.yml"
    EOY
  end

  subject { described_class.new(pipeline, command) }

  shared_examples 'does not include compliance pipeline configuration content' do
    it do
      subject.perform!

      expect(pipeline.config_source).not_to eq 'compliance_source'
      expect(pipeline.pipeline_config.content).not_to eq(content_result)
      expect(command.config_content).not_to eq(content_result)
    end
  end

  context 'when project has compliance label defined' do
    let(:project) { create(:project, ci_config_path: ci_config_path) }
    let(:compliance_group) { create(:group, :private, name: "compliance") }
    let(:compliance_project) { create(:project, namespace: compliance_group, name: "hippa") }

    context 'when feature is available' do
      before do
        stub_feature_flags(ff_evaluate_group_level_compliance_pipeline: true)
        stub_licensed_features(evaluate_group_level_compliance_pipeline: true)
      end

      context 'when compliance pipeline configuration is defined' do
        let(:framework) do
          create(:compliance_framework,
                 namespace: compliance_group,
                 pipeline_configuration_full_path: ".compliance-gitlab-ci.yml@compliance/hippa")
        end

        let!(:framework_project_setting) do
          create(:compliance_framework_project_setting, project: project, compliance_management_framework: framework)
        end

        it 'includes compliance pipeline configuration content' do
          subject.perform!

          expect(pipeline.config_source).to eq 'compliance_source'
          expect(pipeline.pipeline_config.content).to eq(content_result)
          expect(command.config_content).to eq(content_result)
        end
      end

      context 'when compliance pipeline configuration is not defined' do
        let(:framework) { create(:compliance_framework, namespace: compliance_group) }
        let!(:framework_project_setting) do
          create(:compliance_framework_project_setting, project: project, compliance_management_framework: framework)
        end

        it_behaves_like 'does not include compliance pipeline configuration content'
      end

      context 'when compliance pipeline configuration is empty' do
        let(:framework) do
          create(:compliance_framework, namespace: compliance_group, pipeline_configuration_full_path: '')
        end

        let!(:framework_project_setting) do
          create(:compliance_framework_project_setting, project: project, compliance_management_framework: framework)
        end

        it_behaves_like 'does not include compliance pipeline configuration content'
      end
    end

    context 'when feature is not available' do
      using RSpec::Parameterized::TableSyntax

      where(:licensed, :feature_flag) do
        true  | false
        false | true
        false | false
      end

      with_them do
        before do
          stub_feature_flags(ff_evaluate_group_level_compliance_pipeline: licensed)
          stub_licensed_features(evaluate_group_level_compliance_pipeline: feature_flag)
        end

        it_behaves_like 'does not include compliance pipeline configuration content'
      end
    end
  end

  context 'when project does not have compliance label defined' do
    let(:project) { create(:project, ci_config_path: ci_config_path) }

    context 'when feature is available' do
      before do
        stub_feature_flags(ff_evaluate_group_level_compliance_pipeline: true)
        stub_licensed_features(evaluate_group_level_compliance_pipeline: true)
      end

      it_behaves_like 'does not include compliance pipeline configuration content'
    end
  end
end
