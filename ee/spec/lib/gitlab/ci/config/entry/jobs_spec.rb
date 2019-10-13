# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Jobs do
  let(:config) do
    {
      '.hidden_job'.to_sym => { script: 'something' },
      '.hidden_bridge'.to_sym => { trigger: 'my/project' },
      regular_job: { script: 'something' },
      my_trigger: { trigger: 'my/project' }
    }
  end

  describe '.all_types' do
    subject { described_class.all_types }

    it { is_expected.to include(::EE::Gitlab::Ci::Config::Entry::Bridge) }
  end

  describe '.find_type' do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.find_type(name, config[name]) }

    context 'when cross-project pipeline triggers are enabled' do
      before do
        stub_feature_flags(cross_project_pipeline_triggers: true)
      end

      where(:name, :type) do
        :'.hidden_job'    | ::Gitlab::Ci::Config::Entry::Hidden
        :'.hidden_bridge' | ::Gitlab::Ci::Config::Entry::Hidden
        :regular_job      | ::Gitlab::Ci::Config::Entry::Job
        :my_trigger       | ::EE::Gitlab::Ci::Config::Entry::Bridge
      end

      with_them do
        it { is_expected.to eq(type) }
      end
    end

    context 'when cross-project pipeline triggers are disabled' do
      before do
        stub_feature_flags(cross_project_pipeline_triggers: false)
      end

      where(:name, :type) do
        :'.hidden_job'    | ::Gitlab::Ci::Config::Entry::Hidden
        :'.hidden_bridge' | ::Gitlab::Ci::Config::Entry::Hidden
        :regular_job      | ::Gitlab::Ci::Config::Entry::Job
        :my_trigger       | nil
      end

      with_them do
        it { is_expected.to eq(type) }
      end
    end
  end

  describe '.new' do
    subject do
      described_class.new(config)
    end

    context 'when cross-project pipeline triggers are enabled' do
      before do
        stub_feature_flags(cross_project_pipeline_triggers: true)

        subject.compose!
      end

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'returns a correct hash representing all jobs' do
          expect(subject.value).to eq(
            my_trigger: {
              name: :my_trigger,
              trigger: { project: 'my/project' },
              stage: 'test',
              only: { refs: %w[branches tags] },
              ignore: false
            },
            regular_job: {
              script: %w[something],
              name: :regular_job,
              stage: 'test',
              only: { refs: %w[branches tags] },
              variables: {},
              ignore: false
            })
        end
      end
    end

    context 'when cross-project pipeline triggers are disabled' do
      before do
        stub_feature_flags(cross_project_pipeline_triggers: false)

        subject.compose!
      end

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end
    end
  end
end
