# frozen_string_literal: true

require 'spec_helper'

describe EE::Gitlab::Ci::Config::Entry::Bridge do
  subject { described_class.new(config, name: :my_bridge) }

  it_behaves_like 'with inheritable CI config' do
    let(:inheritable_key) { 'default' }
    let(:inheritable_class) { Gitlab::Ci::Config::Entry::Default }

    # These are entries defined in Default
    # that we know that we don't want to inherit
    # as they do not have sense in context of Bridge
    let(:ignored_inheritable_columns) do
      %i[before_script after_script image services cache interruptible timeout retry]
    end
  end

  describe '.matching?' do
    subject { described_class.matching?(name, config) }

    context 'when config is not a hash' do
      let(:name) { :my_trigger }
      let(:config) { 'string' }

      it { is_expected.to be_falsey }
    end

    context 'when config is a regular job' do
      let(:name) { :my_trigger }
      let(:config) do
        { script: 'ls -al' }
      end

      it { is_expected.to be_falsey }
    end

    context 'when config is a bridge job' do
      let(:name) { :my_trigger }
      let(:config) do
        { trigger: 'other-project' }
      end

      it { is_expected.to be_truthy }
    end

    context 'when config is a hidden job' do
      let(:name) { '.my_trigger' }
      let(:config) do
        { trigger: 'other-project' }
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '.new' do
    before do
      subject.compose!
    end

    context 'when trigger config is a non-empty string' do
      let(:config) { { trigger: 'some/project' } }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'is returns a bridge job configuration' do
          expect(subject.value).to eq(name: :my_bridge,
                                      trigger: { project: 'some/project' },
                                      ignore: false,
                                      stage: 'test',
                                      only: { refs: %w[branches tags] })
        end
      end
    end

    context 'when needs pipeline config is a non-empty string' do
      let(:config) { { needs: { pipeline: 'some/project' } } }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'is returns a bridge job configuration' do
          expect(subject.value).to eq(name: :my_bridge,
                                      needs: { bridge: [{ pipeline: 'some/project' }] },
                                      ignore: false,
                                      stage: 'test',
                                      only: { refs: %w[branches tags] })
        end
      end
    end

    context 'when bridge trigger is a hash' do
      let(:config) do
        { trigger: { project: 'some/project', branch: 'feature' } }
      end

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'is returns a bridge job configuration hash' do
          expect(subject.value).to eq(name: :my_bridge,
                                      trigger: { project: 'some/project',
                                                 branch: 'feature' },
                                      ignore: false,
                                      stage: 'test',
                                      only: { refs: %w[branches tags] })
        end
      end
    end

    context 'when bridge configuration contains all supported keys' do
      let(:config) do
        { trigger: { project: 'some/project', branch: 'feature' },
          needs: { pipeline: 'other/project' },
          when: 'always',
          extends: '.some-key',
          stage: 'deploy',
          only: { variables: %w[$SOMEVARIABLE] },
          except: { refs: %w[feature] },
          variables: { VARIABLE: '123' } }
      end

      it { is_expected.to be_valid }
    end

    context 'when trigger config is nil' do
      let(:config) { { trigger: nil } }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'is returns an error about empty trigger config' do
          expect(subject.errors.first).to eq('bridge config should contain either a trigger or a needs:pipeline')
        end
      end
    end

    context 'when upstream config is nil' do
      let(:config) { { needs: nil } }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'is returns an error about empty upstream config' do
          expect(subject.errors.first).to eq('bridge config should contain either a trigger or a needs:pipeline')
        end
      end
    end

    context 'when bridge has only job needs' do
      let(:config) do
        {
          needs: ['some_job']
        }
      end

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end
    end

    context 'when bridge has bridge and job needs' do
      let(:config) do
        {
          trigger: 'other-project',
          needs: ['some_job', { pipeline: 'some/other_project' }]
        }
      end

      describe '#valid?' do
        it { is_expected.to be_valid }
      end
    end

    context 'when bridge has more than one valid bridge needs' do
      let(:config) do
        {
          trigger: 'other-project',
          needs: [{ pipeline: 'some/project' }, { pipeline: 'some/other_project' }]
        }
      end

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns an error about too many bridge needs' do
          expect(subject.errors).to contain_exactly('bridge config should contain at most one bridge need')
        end
      end
    end

    context 'when bridge config contains unknown keys' do
      let(:config) { { unknown: 123 } }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'is returns an error about unknown config key' do
          expect(subject.errors.first)
            .to match /config contains unknown keys: unknown/
        end
      end
    end

    context 'when bridge config contains build-specific attributes' do
      let(:config) { { script: 'something' } }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns an error message' do
          expect(subject.errors.first)
            .to match /contains unknown keys: script/
        end
      end
    end
  end
end
