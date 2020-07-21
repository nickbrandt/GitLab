# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Template::MetricsDashboardTemplate do
  subject { described_class }

  describe '.all' do
    it 'strips the metrics-dashboard suffix' do
      expect(subject.all.first.name).not_to end_with('metrics-dashboard.yml')
    end

    it 'combines the globals and rest' do
      all = subject.all.map(&:name)

      expect(all).to include('Default')
    end

    it 'ensures that the template name is used exactly once' do
      all = subject.all.group_by(&:name)
      duplicates = all.select { |_, templates| templates.length > 1 }

      expect(duplicates).to be_empty
    end
  end

  describe '.find' do
    it 'returns nil if the file does not exist' do
      expect(subject.find('nonexistent-file')).to be nil
    end

    it 'returns the MetricsDashboardYml object of a valid file' do
      default_dashboard = subject.find('Default')

      expect(default_dashboard).to be_a described_class
      expect(default_dashboard.name).to eq('Default')
    end
  end

  describe '.by_category' do
    it 'returns sorted results' do
      result = described_class.by_category('General')

      expect(result).to eq(result.sort)
    end
  end

  describe '#content' do
    it 'loads the full file' do
      example_dashboard = subject.new(Rails.root.join('lib/gitlab/metrics/templates/Default.metrics-dashboard.yml'))

      expect(example_dashboard.name).to eq 'Default'
      expect(example_dashboard.content).to start_with('#')
    end
  end

  describe '#<=>' do
    it 'sorts lexicographically' do
      one = described_class.new('a.metrics-dashboard.yml')
      other = described_class.new('z.metrics-dashboard.yml')

      expect(one.<=>(other)).to be(-1)
      expect([other, one].sort).to eq([one, other])
    end
  end
end
