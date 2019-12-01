# frozen_string_literal: true

require 'spec_helper'

describe Vulnerabilities::IssueLink do
  describe 'associations and fields' do
    it { is_expected.to belong_to(:vulnerability) }
    it { is_expected.to belong_to(:issue) }
    it { is_expected.to define_enum_for(:link_type).with_values(related: 1, created: 2) }

    it 'provides the "related" as default link_type' do
      expect(create(:vulnerabilities_issue_link).link_type).to eq 'related'
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:vulnerability) }
    it { is_expected.to validate_presence_of(:issue) }
  end

  context 'when there is a link between the same vulnerability and issue' do
    let!(:existing_link) { create(:vulnerabilities_issue_link) }

    it 'raises the uniqueness violation error' do
      expect do
        create(:vulnerabilities_issue_link,
          issue: existing_link.issue,
          vulnerability: existing_link.vulnerability)
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  context 'when there is an existing "created" issue link for vulnerability' do
    let!(:existing_link) { create(:vulnerabilities_issue_link, :created) }

    it 'prevents the creation of a new "created" issue link' do
      expect do
        create(:vulnerabilities_issue_link,
               :created,
               vulnerability: existing_link.vulnerability,
               issue: create(:issue))
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows the creation of a new "related" issue link' do
      expect do
        create(:vulnerabilities_issue_link,
               :related,
               vulnerability: existing_link.vulnerability,
               issue: create(:issue))
      end.not_to raise_error
    end
  end
end
