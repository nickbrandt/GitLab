# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::WebIde::Config::Entry::Terminal do
  let(:entry) { described_class.new(config) }

  describe '.nodes' do
    context 'when filtering all the entry/node names' do
      subject { described_class.nodes.keys }

      let(:result) do
        %i[before_script script image services variables]
      end

      it { is_expected.to match_array result }
    end
  end

  describe 'validations' do
    before do
      entry.compose!
    end

    context 'when entry config value is correct' do
      let(:config) { { script: 'rspec' } }

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when entry value is not correct' do
      context 'incorrect config value type' do
        let(:config) { ['incorrect'] }

        describe '#errors' do
          it 'reports error about a config type' do
            expect(entry.errors)
              .to include 'terminal config should be a hash'
          end
        end
      end

      context 'when config is empty' do
        let(:config) { {} }

        describe '#valid' do
          it 'is valid' do
            expect(entry).to be_valid
          end
        end
      end

      context 'when unknown keys detected' do
        let(:config) { { unknown: true } }

        describe '#valid' do
          it 'is not valid' do
            expect(entry).not_to be_valid
          end
        end
      end
    end
  end

  describe '#relevant?' do
    it 'is a relevant entry' do
      entry = described_class.new({ script: 'rspec' })

      expect(entry).to be_relevant
    end
  end

  context 'when composed' do
    before do
      entry.compose!
    end

    describe '#value' do
      before do
        entry.compose!
      end

      context 'when entry is correct' do
        let(:config) do
          { before_script: %w[ls pwd],
            script: 'sleep 100',
            tags: ['webide'],
            image: 'ruby:2.5',
            services: ['mysql'],
            variables: { KEY: 'value' } }
        end

        it 'returns correct value' do
          expect(entry.value)
            .to eq(
              tag_list: ['webide'],
              yaml_variables: [{ key: 'KEY', value: 'value', public: true }],
              options: {
                image: { name: "ruby:2.5" },
                services: [{ name: "mysql" }],
                before_script: %w[ls pwd],
                script: ['sleep 100']
              }
            )
        end
      end
    end
  end
end
