# frozen_string_literal: true

require_relative '../../../../tooling/lib/tooling/rspec_parallel_calculator'

RSpec.describe Tooling::RSpecParallelCalculator do # rubocop:disable RSpec/FilePath
  let(:target_minutes) { 1 }
  let(:test_level) { instance_double('Quality::TestLevel') }
  let(:knapsack_report) do
    {
      'spec/unit/a_spec.rb' => 60,
      'spec/unit/b_spec.rb' => 90,
      'spec/unit/c_spec.rb' => 120,
      'ee/spec/unit/a_spec.rb' => 400,
      'ee/spec/unit/b_spec.rb' => 140,
      'spec/migration/a_spec.rb' => 120,
      'ee/spec/migration/a_spec.rb' => 180,
      'spec/integration/a_spec.rb' => 2400,
      'ee/spec/integration/a_spec.rb' => 3000,
      'spec/system/a_spec.rb' => 600,
      'ee/spec/system/a_spec.rb' => 900
    }
  end

  before do
    stub_test_level(test_level)
  end

  describe '#parallel_count' do
    context 'when foss' do
      subject { described_class.new(knapsack_report, target_minutes: target_minutes, test_level: test_level) }

      context 'when level is unit' do
        it 'returns number of jobs to achieve target duration, rounded up' do
          expect(subject.parallel_count(project: :foss, level: :unit)).to eq(5)
        end
      end

      context 'when level is integration' do
        it 'returns number of jobs to achieve target duration, rounded up' do
          expect(subject.parallel_count(project: :foss, level: :integration)).to eq(40)
        end
      end

      context 'when level is migration' do
        it 'returns number of jobs to achieve target duration, rounded up' do
          expect(subject.parallel_count(project: :foss, level: :migration)).to eq(2)
        end
      end

      context 'when level is system' do
        it 'returns number of jobs to achieve target duration, rounded up' do
          expect(subject.parallel_count(project: :foss, level: :system)).to eq(10)
        end
      end
    end

    context 'when ee' do
      subject { described_class.new(knapsack_report, target_minutes: target_minutes, test_level: test_level) }

      context 'when level is unit' do
        it 'returns number of jobs to achieve target duration, rounded up' do
          expect(subject.parallel_count(project: :ee, level: :unit)).to eq(9)
        end
      end

      context 'when level is integration' do
        it 'returns number of jobs to achieve target duration, rounded up' do
          expect(subject.parallel_count(project: :ee, level: :integration)).to eq(50)
        end
      end

      context 'when level is migration' do
        it 'returns number of jobs to achieve target duration, rounded up' do
          expect(subject.parallel_count(project: :ee, level: :migration)).to eq(3)
        end
      end

      context 'when level is system' do
        it 'returns number of jobs to achieve target duration, rounded up' do
          expect(subject.parallel_count(project: :ee, level: :system)).to eq(15)
        end
      end
    end

    context 'when target minutes is nil' do
      subject { described_class.new(knapsack_report, target_minutes: nil, test_level: test_level) }

      before do
        stub_const('Tooling::RSpecParallelCalculator::DEFAULT_TARGET_MINUTES', 2)
      end

      it 'uses DEFAULT_TARGET_MINUTES' do
        expect(subject.parallel_count(project: :foss, level: :integration)).to eq(20)
      end
    end
  end

  private

  def stub_test_level(test_level)
    allow(test_level).to receive(:level_for) do |path|
      case path
      when /unit/ then :unit
      when /migration/ then :migration
      when /integration/ then :integration
      when /system/ then :system
      else raise 'unknown test level'
      end
    end
  end
end
