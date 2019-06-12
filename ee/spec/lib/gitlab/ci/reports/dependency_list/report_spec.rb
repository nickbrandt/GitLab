# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Reports::DependencyList::Report do
  let(:report) { described_class.new }

  describe '#add_dependency' do
    let(:dependency) { { name: 'gitlab', version: '12.0' } }

    subject { report.add_dependency(dependency) }

    it 'stores given dependency params in the map' do
      subject

      expect(report.dependencies).to eq([dependency])
    end
  end
end
