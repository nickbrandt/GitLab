# frozen_string_literal: true

require 'fast_spec_helper'

describe Atlassian::JiraIssueKeyExtractor do
  describe '#issue_keys' do
    subject { described_class.new('TEST-01 Some A-100 issue title OTHER-02 ABC!-1 that mentions Jira issue').issue_keys }

    it 'returns all valid Jira issue keys' do
      is_expected.to contain_exactly('TEST-01', 'OTHER-02')
    end

    context 'when multiple strings are passed in' do
      subject { described_class.new('TEST-01 Some A-100', 'issue title OTHER', '-02 ABC!-1 that mentions Jira issue').issue_keys }

      it 'returns all valid Jira issue keys in any of those string' do
        is_expected.to contain_exactly('TEST-01')
      end
    end
  end
end
