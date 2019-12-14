# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::YamlProcessor do
  describe 'Bridge Needs' do
    let(:config) do
      {
        build: { stage: 'build', script: 'test' },
        bridge: { stage: 'test', needs: needs }
      }
    end

    subject { described_class.new(YAML.dump(config)) }

    context 'needs upstream pipeline' do
      let(:needs) { { pipeline: 'some/project' } }

      it 'creates jobs with valid specification' do
        expect(subject.builds.size).to eq(2)
        expect(subject.builds[0]).to eq(
          stage: "build",
          stage_idx: 1,
          name: "build",
          options: {
            script: ["test"]
          },
          when: "on_success",
          allow_failure: false,
          yaml_variables: []
        )
        expect(subject.builds[1]).to eq(
          stage: "test",
          stage_idx: 2,
          name: "bridge",
          options: {
            bridge_needs: { pipeline: 'some/project' }
          },
          when: "on_success",
          allow_failure: false,
          yaml_variables: []
        )
      end
    end

    context 'needs both job and pipeline' do
      let(:needs) { ['build', { pipeline: 'some/project' }] }

      it 'creates jobs with valid specification' do
        expect(subject.builds.size).to eq(2)
        expect(subject.builds[0]).to eq(
          stage: "build",
          stage_idx: 1,
          name: "build",
          options: {
            script: ["test"]
          },
          when: "on_success",
          allow_failure: false,
          yaml_variables: []
        )
        expect(subject.builds[1]).to eq(
          stage: "test",
          stage_idx: 2,
          name: "bridge",
          options: {
            bridge_needs: { pipeline: 'some/project' }
          },
          needs_attributes: [
            { name: "build", artifacts: true }
          ],
          when: "on_success",
          allow_failure: false,
          yaml_variables: []
        )
      end
    end
  end
end
