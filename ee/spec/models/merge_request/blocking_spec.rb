# frozen_string_literal: true

require 'spec_helper'

describe MergeRequest do
  let(:block) { create(:merge_request_block) }

  let(:blocking_mr) { block.blocking_merge_request }
  let(:blocked_mr) { block.blocked_merge_request }

  describe 'associations' do
    it { expect(blocking_mr.blocks_as_blocker).to contain_exactly(block) }
    it { expect(blocking_mr.blocks_as_blockee).to be_empty }

    it { expect(blocked_mr.blocks_as_blocker).to be_empty }
    it { expect(blocked_mr.blocks_as_blockee).to contain_exactly(block) }

    it { expect(blocking_mr.blocking_merge_requests).to be_empty }
    it { expect(blocking_mr.blocked_merge_requests).to contain_exactly(blocked_mr) }

    it { expect(blocked_mr.blocking_merge_requests).to contain_exactly(blocking_mr) }
    it { expect(blocked_mr.blocked_merge_requests).to be_empty }
  end

  describe '#mergeable? (blocking MRs)' do
    it 'checks MergeRequest#merge_blocked_by_other_mrs?' do
      expect(blocked_mr).to receive(:merge_blocked_by_other_mrs?) { true }

      expect(blocked_mr.mergeable?).to be(false)
    end
  end

  describe '#merge_blocked_by_other_mrs?' do
    context 'licensed' do
      before do
        stub_licensed_features(blocking_merge_requests: true)
      end

      it 'is false for the blocking MR' do
        expect(blocking_mr.merge_blocked_by_other_mrs?).to be(false)
      end

      it 'is true for the blocked MR when the blocking MR is open' do
        expect(blocked_mr.merge_blocked_by_other_mrs?).to be(true)
      end

      it 'is true for the blocked MR when the blocking MR is closed' do
        blocking_mr.close!

        expect(blocked_mr.merge_blocked_by_other_mrs?).to be(true)
      end

      it 'is false for the blocked MR when the blocking MR is merged' do
        blocking_mr.state = 'merged'
        blocking_mr.save!(validate: false)

        expect(blocked_mr.merge_blocked_by_other_mrs?).to be(false)
      end
    end

    context 'unlicensed' do
      before do
        stub_licensed_features(blocking_merge_requests: false)
      end

      it 'is false for the blocked MR' do
        expect(blocked_mr.merge_blocked_by_other_mrs?).to be(false)
      end
    end
  end
end
