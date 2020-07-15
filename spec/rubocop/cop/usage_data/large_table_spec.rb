# frozen_string_literal: true

require 'fast_spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/usage_data/large_table'

RSpec.describe RuboCop::Cop::UsageData::LargeTable, type: :rubocop do
  include CopHelper

  let(:large_tables) { %i[Rails Time] }
  let(:count_methods) { %i[count distinct_count] }
  let(:allowed_methods) { %i[minimum maximum] }

  let(:config) do
    RuboCop::Config.new('UsageData/LargeTable' => {
                          'NonRelatedClasses' => large_tables,
                          'CountMethods' => count_methods,
                          'AllowedMethods' => allowed_methods
                        })
  end

  subject(:cop) { described_class.new(config) }

  context 'when in usage_data files' do
    before do
      allow(cop).to receive(:usage_data_files?).and_return(true)
    end

    context 'with large tables' do
      context 'when counting' do
        let(:source) do
          <<~SRC
            Issue.count
          SRC
        end

        let(:source_with_count_ancestor) do
          <<~SRC
            Issue.active.count
          SRC
        end

        let(:correct_source) do
          <<~SRC
            count(Issue)
          SRC
        end

        let(:correct_source_with_module) do
          <<~SRC
            count(Ci::Build.active)
          SRC
        end

        let(:incorrect_source_with_module) do
          <<~SRC
            Ci::Build.active.count
          SRC
        end

        it 'registers an offence' do
          inspect_source(source)

          expect(cop.offenses.size).to eq(1)
        end

        it 'registers an offence with .count' do
          inspect_source(source_with_count_ancestor)

          expect(cop.offenses.size).to eq(1)
        end

        it 'does not register an offence' do
          inspect_source(correct_source)

          expect(cop.offenses).to be_empty
        end
      end

      context 'when using allowed methods' do
        let(:source) do
          <<~SRC
            Issue.minimum
          SRC
        end

        it 'does not register an offence' do
          inspect_source(source)

          expect(cop.offenses).to be_empty
        end
      end
    end

    context 'with non related class' do
      let(:source) do
        <<~SRC
          Rails.count
        SRC
      end

      it 'does not registers an offence' do
        inspect_source(source)

        expect(cop.offenses).to be_empty
      end
    end
  end
end
