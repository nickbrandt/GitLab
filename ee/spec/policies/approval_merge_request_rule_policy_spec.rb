# frozen_string_literal: true

require 'spec_helper'

describe ApprovalMergeRequestRulePolicy do
  let(:merge_request) { create(:merge_request) }
  let!(:approval_rule) { create(:approval_merge_request_rule, merge_request: merge_request) }

  def permissions(user, approval_rule)
    described_class.new(user, approval_rule)
  end

  context 'when user can update merge request' do
    it 'allows updating approval rule' do
      expect(permissions(merge_request.author, approval_rule)).to be_allowed(:edit_approval_rule)
    end
  end

  context 'when user cannot update merge request' do
    it 'disallow updating approval rule' do
      expect(permissions(create(:user), approval_rule)).to be_disallowed(:edit_approval_rule)
    end
  end
end
