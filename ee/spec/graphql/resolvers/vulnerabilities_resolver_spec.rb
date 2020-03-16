# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::VulnerabilitiesResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:project) { create(:project) }
    let_it_be(:low_vulnerability) { create(:vulnerability, :low, project: project) }
    let_it_be(:critical_vulnerability) { create(:vulnerability, :critical, project: project) }
    let_it_be(:high_vulnerability) { create(:vulnerability, :high, project: project) }

    subject { resolve(described_class, obj: project) }

    it "returns the project's vulnerabilities" do
      is_expected.to contain_exactly(critical_vulnerability, high_vulnerability, low_vulnerability)
    end

    it 'orders results by severity' do
      expect(subject.first).to eq(critical_vulnerability)
      expect(subject.second).to eq(high_vulnerability)
      expect(subject.third).to eq(low_vulnerability)
    end
  end
end
