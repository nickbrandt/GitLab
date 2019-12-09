# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::ByApprovalsFinder do
  set(:first_user) { create(:user) }
  set(:second_user) { create(:user) }

  set(:merge_request_without_approvals) { create(:merge_request) }
  set(:merge_request_with_first_user_approval) do
    create(:merge_request).tap do |mr|
      create(:approval, merge_request: mr, user: first_user)
    end
  end
  set(:merge_request_with_both_approvals) do
    create(:merge_request).tap do |mr|
      create(:approval, merge_request: mr, user: first_user)
      create(:approval, merge_request: mr, user: second_user)
    end
  end

  def merge_requests(ids: nil, names: [])
    described_class.new(names, ids).execute(MergeRequest.all)
  end

  context 'filter by no approvals' do
    it 'returns merge requests without approvals' do
      expected_result = [merge_request_without_approvals]

      expect(merge_requests(ids: 'None')).to eq(expected_result)
      expect(merge_requests(names: ['None'])).to eq(expected_result)
    end
  end

  context 'filter by any approvals' do
    it 'returns merge requests approved by at least one user' do
      expected_result = [merge_request_with_first_user_approval, merge_request_with_both_approvals]

      expect(merge_requests(ids: 'Any')).to eq(expected_result)
      expect(merge_requests(names: ['Any'])).to eq(expected_result)
    end
  end

  context 'filter by specific user approval' do
    it 'returns merge requests approved by specific user' do
      expected_result = [merge_request_with_first_user_approval, merge_request_with_both_approvals]

      expect(merge_requests(ids: [first_user.id])).to eq(expected_result)
      expect(merge_requests(names: [first_user.username])).to eq(expected_result)
    end
  end

  context 'filter by multiple user approval' do
    it 'returns merge requests approved by both users' do
      expected_result = [merge_request_with_both_approvals]

      expect(merge_requests(ids: [first_user.id, second_user.id])).to match_array(expected_result)
      expect(merge_requests(names: [first_user.username, second_user.username])).to match_array(expected_result)
    end
  end

  context 'with empty params' do
    it 'returns all merge requests' do
      expected_result = [merge_request_without_approvals, merge_request_with_first_user_approval, merge_request_with_both_approvals]

      expect(merge_requests(ids: [])).to match_array(expected_result)
      expect(merge_requests(names: [])).to match_array(expected_result)
    end
  end
end
