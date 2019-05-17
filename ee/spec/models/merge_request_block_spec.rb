# frozen_string_literal: true

require 'spec_helper'

describe MergeRequestBlock do
  describe 'associations' do
    it { is_expected.to belong_to(:blocking_merge_request).class_name('MergeRequest') }
    it { is_expected.to belong_to(:blocked_merge_request).class_name('MergeRequest') }
  end

  describe 'validations' do
    subject(:block) { create(:merge_request_block) }

    let(:blocking_mr) { block.blocking_merge_request }
    let(:blocked_mr) { block.blocked_merge_request }
    let(:another_mr) { create(:merge_request) }

    it { is_expected.to validate_presence_of(:blocking_merge_request) }
    it { is_expected.to validate_presence_of(:blocked_merge_request) }

    it 'forbids the blocking MR from being the blocked MR' do
      block.blocking_merge_request = block.blocked_merge_request

      expect(block).not_to be_valid
    end

    it 'allows an MR to block multiple MRs' do
      another_block = described_class.new(
        blocking_merge_request: blocking_mr,
        blocked_merge_request: another_mr
      )

      expect(another_block).to be_valid
    end

    it 'allows an MR to be blocked by multiple MRs' do
      another_block = described_class.new(
        blocking_merge_request: another_mr,
        blocked_merge_request: blocked_mr
      )

      expect(another_block).to be_valid
    end

    it 'forbids duplicate blocks' do
      new_block = described_class.new(block.attributes)

      expect(new_block).not_to be_valid
    end

    it 'forbids blocking MR from becoming blocked' do
      new_block = build(:merge_request_block, blocked_merge_request: block.blocking_merge_request)

      expect(new_block).not_to be_valid
    end

    it 'forbids blocked MR from becoming a blocker' do
      new_block = build(:merge_request_block, blocking_merge_request: block.blocked_merge_request)

      expect(new_block).not_to be_valid
    end
  end
end
