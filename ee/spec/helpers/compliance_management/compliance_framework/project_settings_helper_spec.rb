# frozen_string_literal: true

require 'spec_helper'

describe ComplianceManagement::ComplianceFramework::ProjectSettingsHelper do
  let(:frameworks) { ComplianceManagement::ComplianceFramework::ProjectSettings.frameworks.keys }
  let(:descriptions) { helper.compliance_framework_option_values }

  describe '#compliance_framework_options' do
    it 'has all the descriptions' do
      expect(helper.compliance_framework_options.map(&:first)).to eq(descriptions.map(&:last))
    end

    it 'has all the frameworks' do
      expect(helper.compliance_framework_options.map(&:last)).to eq(frameworks)
    end
  end

  describe '#compliance_framework_option_values' do
    it 'returns a hash' do
      expect(helper.compliance_framework_option_values).to be_a_kind_of(Hash)
    end

    it 'is the same length as frameworks' do
      expect(helper.compliance_framework_option_values.length).to equal(frameworks.length)
    end
  end
end
