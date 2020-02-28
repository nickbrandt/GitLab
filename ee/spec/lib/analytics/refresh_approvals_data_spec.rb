# frozen_string_literal: true

require 'spec_helper'

describe Analytics::RefreshApprovalsData do
  subject { described_class.new(merge_request) }

  let!(:approval) { create(:approval) }
  let(:merge_request) { approval.merge_request }

  describe '#execute' do
    it 'updates mr first_approved_at metric' do
      expect do
        subject.execute
        merge_request.metrics.reload
      end.to change { merge_request.metrics.first_approved_at }.from(nil).to(be_like_time(approval.created_at))
    end

    context 'when first_approved_at is already present' do
      before do
        merge_request.metrics.update(first_approved_at: 3.days.ago.beginning_of_day)
      end

      it 'does not change mr first_approved_at metric' do
        expect do
          subject.execute
          merge_request.metrics.reload
        end.not_to change { merge_request.metrics.first_approved_at }
      end

      it 'updates mr first_approved_at metric if forced' do
        expect do
          subject.execute(force: true)
          merge_request.metrics.reload
        end.to change { merge_request.metrics.first_approved_at }.to(be_like_time(approval.created_at))
      end
    end

    context 'when no merge request metric is present' do
      before do
        merge_request.metrics.destroy
        merge_request.reload
      end

      it 'creates one' do
        expect { subject.execute }
          .to change { merge_request.metrics&.first_approved_at }.from(nil).to(be_like_time(approval.created_at))
      end
    end
  end
end
