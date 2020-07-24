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
      context 'when calling Issue.count' do
        it 'register an offence' do
          inspect_source <<~SRC
            Issue.count
          SRC

          expect(cop.offenses.size).to eq(1)
        end
      end

      context 'when calling Issue.active.count' do
        it 'register an offence' do
          inspect_source <<~SRC
            Issue.active.count
          SRC

          expect(cop.offenses.size).to eq(1)
        end
      end

      context 'when calling count(Issue)' do
        it 'does not register an offence' do
          inspect_source <<~SRC
            count(Issue)
          SRC

          expect(cop.offenses).to be_empty
        end
      end

      context 'when calling count(Ci::Build.active)' do
        it 'does not register an offence' do
          inspect_source <<~SRC
            count(Ci::Build.active)
          SRC

          expect(cop.offenses).to be_empty
        end
      end

      context 'when calling Ci::Build.active.count' do
        it 'register an offence' do
          inspect_source <<~SRC
            Ci::Build.active.count
          SRC

          expect(cop.offenses.size).to eq(1)
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
      it 'does not register an offence' do
        inspect_source <<~SRC
          Rails.count
        SRC

        expect(cop.offenses).to be_empty
      end
    end
  end
end
