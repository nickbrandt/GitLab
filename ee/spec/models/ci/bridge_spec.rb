require 'spec_helper'

describe Ci::Bridge do
  set(:project) { create(:project) }
  set(:pipeline) { create(:ci_pipeline, project: project) }

  let(:bridge) do
    create(:ci_bridge, :variables, status: :created,
                                   options: options,
                                   pipeline: pipeline)
  end

  let(:options) do
    { trigger: { project: 'my/project', branch: 'master' } }
  end

  it 'has many sourced pipelines' do
    expect(bridge).to have_many(:sourced_pipelines)
  end

  describe 'state machine transitions' do
    context 'when it changes status from created to pending' do
      it 'schedules downstream pipeline creation' do
        expect(bridge).to receive(:schedule_downstream_pipeline!)

        bridge.enqueue!
      end
    end
  end

  describe '#target_user' do
    it 'is the same as a user who created a pipeline' do
      expect(bridge.target_user).to eq bridge.user
    end
  end

  describe '#target_project_path' do
    context 'when trigger is defined' do
      it 'returns a full path of a project' do
        expect(bridge.target_project_path).to eq 'my/project'
      end
    end

    context 'when trigger does not have project defined' do
      let(:options) { { trigger: {} } }

      it 'returns nil' do
        expect(bridge.target_project_path).to be_nil
      end
    end
  end

  describe '#target_ref' do
    context 'when trigger is defined' do
      it 'returns a ref name' do
        expect(bridge.target_ref).to eq 'master'
      end
    end

    context 'when trigger does not have project defined' do
      let(:options) { nil }

      it 'returns nil' do
        expect(bridge.target_ref).to be_nil
      end
    end
  end

  describe '#yaml_variables' do
    it 'returns YAML variables' do
      expect(bridge.yaml_variables)
        .to include(key: 'BRIDGE', value: 'cross', public: true)
    end
  end

  describe '#downstream_variables' do
    it 'returns variables that are going to be passed downstream' do
      expect(bridge.downstream_variables)
        .to include(key: 'BRIDGE', value: 'cross')
    end
  end

  describe 'metadata support' do
    it 'reads YAML variables from metadata' do
      expect(bridge.yaml_variables).not_to be_empty
      expect(bridge.metadata).to be_a Ci::BuildMetadata
      expect(bridge.read_attribute(:yaml_variables)).to be_nil
      expect(bridge.metadata.config_variables).to be bridge.yaml_variables
    end

    it 'reads options from metadata' do
      expect(bridge.options).not_to be_empty
      expect(bridge.metadata).to be_a Ci::BuildMetadata
      expect(bridge.read_attribute(:options)).to be_nil
      expect(bridge.metadata.config_options).to be bridge.options
    end
  end
end
