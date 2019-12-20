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
          only: { refs: %w[branches tags] },
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
          only: { refs: %w[branches tags] },
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
          only: { refs: %w[branches tags] },
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
          only: { refs: %w[branches tags] },
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

    context 'needs cross projects artifacts' do
      let(:config) do
        {
          build: { stage: 'build', script: 'test' },
          test1: { stage: 'test', script: 'test', needs: needs },
          test2: { stage: 'test', script: 'test' }
        }
      end

      let(:needs) do
        [
          { job: 'build' },
          {
            project: 'some/project',
            ref: 'some/ref',
            job: 'build2',
            artifacts: true
          },
          {
            project: 'some/other/project',
            ref: 'some/ref',
            job: 'build3',
            artifacts: false
          },
          {
            project: 'project',
            ref: 'master',
            job: 'build4'
          }
        ]
      end

      it 'creates jobs with valid specification' do
        expect(subject.builds.size).to eq(3)

        expect(subject.builds[1]).to eq(
          stage: 'test',
          stage_idx: 2,
          name: 'test1',
          options: {
            script: ['test'],
            cross_dependencies: [
              {
                artifacts: true,
                job: 'build2',
                project: 'some/project',
                ref: 'some/ref'
              },
              {
                artifacts: false,
                job: 'build3',
                project: 'some/other/project',
                ref: 'some/ref'
              },
              {
                artifacts: true,
                job: 'build4',
                project: 'project',
                ref: 'master'
              }
            ]
          },
          needs_attributes: [
            { name: 'build', artifacts: true }
          ],
          only: { refs: %w[branches tags] },
          when: 'on_success',
          allow_failure: false,
          yaml_variables: []
        )
      end
    end

    context 'needs cross projects artifacts and pipelines' do
      let(:needs) do
        [
          {
            project: 'some/project',
            ref: 'some/ref',
            job: 'build',
            artifacts: true
          },
          {
            pipeline: 'other/project'
          }
        ]
      end

      it 'returns errors' do
        expect { subject }
          .to raise_error(Gitlab::Ci::YamlProcessor::ValidationError,
                          'jobs:bridge config should contain either a trigger or a needs:pipeline')
      end
    end

    context 'with invalid needs cross projects artifacts' do
      let(:config) do
        {
          build: { stage: 'build', script: 'test' },
          test: {
            stage: 'test',
            script: 'test',
            needs: {
              project: 'some/project',
              ref: 1,
              job: 'build',
              artifacts: true
            }
          }
        }
      end

      it 'returns errors' do
        expect { subject }
          .to raise_error(Gitlab::Ci::YamlProcessor::ValidationError,
                          'jobs:test:needs:need ref should be a string')
      end
    end
  end
end
