# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::FindingIdentifier do
  describe 'associations' do
    it { is_expected.to belong_to(:identifier).class_name('Vulnerabilities::Identifier') }
    it { is_expected.to belong_to(:occurrence).class_name('Vulnerabilities::Occurrence') }
  end

  describe 'validations' do
    let!(:finding_identifier) { create(:vulnerabilities_finding_identifier) }

    it { is_expected.to validate_presence_of(:occurrence) }
    it { is_expected.to validate_presence_of(:identifier) }
    it { is_expected.to validate_uniqueness_of(:identifier_id).scoped_to(:occurrence_id) }
  end
end
