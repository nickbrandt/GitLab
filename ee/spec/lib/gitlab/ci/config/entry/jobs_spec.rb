require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Jobs do
  subject do
    described_class.new(
      {
        '.hidden_job'.to_sym => { script: 'something' },
        regular_job: { script: 'something' },
        my_trigger: { trigger: 'my/project' }
      }
    )
  end

  context 'when cross-project pipeline triggers are enabled' do
    before do
      stub_feature_flags(cross_project_pipeline_triggers: true)

      subject.compose!
    end

    describe '#node_type' do
      it 'correctly identifies hidden jobs' do
        expect(subject.node_type(:'.hidden_job'))
          .to eq ::Gitlab::Ci::Config::Entry::Hidden
      end

      it 'correctly identifies regular jobs' do
        expect(subject.node_type(:regular_job))
          .to eq ::Gitlab::Ci::Config::Entry::Job
      end

      it 'correctly identifies cross-project triggers' do
        expect(subject.node_type(:my_trigger))
          .to eq ::EE::Gitlab::Ci::Config::Entry::Bridge
      end
    end

    describe '#bridge?' do
      it 'returns true when a job is a trigger' do
        expect(subject.bridge?(:my_trigger)).to be true
      end

      it 'returns false when a job is not a trigger' do
        expect(subject.bridge?(:regular_job)).to be false
      end
    end

    describe '#hidden?' do
      it 'does not claim that a bridge job is hidden' do
        expect(subject.hidden?(:my_trigger)).to be false
      end
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

    describe '#node_type' do
      it 'correctly identifies hidden jobs' do
        expect(subject.node_type(:'.hidden_job'))
          .to eq ::Gitlab::Ci::Config::Entry::Hidden
      end

      it 'correctly identifies regular jobs' do
        expect(subject.node_type(:regular_job))
          .to eq ::Gitlab::Ci::Config::Entry::Job
      end

      it 'does not identify trigger job as a bridge job' do
        expect(subject.node_type(:my_trigger))
          .to eq ::Gitlab::Ci::Config::Entry::Job
      end
    end

    describe '#bridge?' do
      it 'returns false even when a job is a trigger' do
        expect(subject.bridge?(:my_trigger)).to be false
      end

      it 'returns false when a job is not a trigger' do
        expect(subject.bridge?(:regular_job)).to be false
      end
    end

    describe '#valid?' do
      it { is_expected.not_to be_valid }
    end
  end
end
