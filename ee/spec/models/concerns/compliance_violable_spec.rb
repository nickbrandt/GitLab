# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceViolable do
  let_it_be(:merge_request) { create(:merge_request) }

  describe '#approved_by_author?' do
    let(:author) { merge_request.author }

    subject { merge_request.approved_by_author? }

    context 'when merge request is approved by someone other than the author' do
      before do
        merge_request.approver_users << create(:user)
      end

      it { is_expected.to be false }

      context 'when merge request is also approved by the author' do
        before do
          merge_request.approver_users << author
        end

        it { is_expected.to be true }
      end
    end

    context 'when merge request is approved by its author' do
      before do
        merge_request.approver_users << author
      end

      it { is_expected.to be true }
    end
  end

  describe '#approved_by_committer?' do
    subject { merge_request.approved_by_committer? }

    context 'when merge request is approved by someone who did not add a commit' do
      let_it_be(:committer) { create(:user) }

      before do
        allow(merge_request).to receive(:committers).and_return([committer])
      end

      it { is_expected.to be false }
    end

    context 'when merge request is approved by someone who also added a commit' do
      let_it_be(:committer) { create(:user) }

      before do
        merge_request.approver_users << committer

        allow(merge_request).to receive(:committers).and_return([committer])
      end

      it { is_expected.to be true }
    end
  end

  describe '#approved_by_insufficient_users' do
    using RSpec::Parameterized::TableSyntax

    subject { merge_request.approved_by_insufficient_users? }

    where(:number_of_approvers, :result) do
      0 | true
      1 | true
      2 | false
      3 | false
    end

    with_them do
      before do
        number_of_approvers.times { merge_request.approver_users << create(:user)}
      end

      it 'expects the correct result depending on the number of approvals' do
        expect(subject).to be(result)
      end
    end
  end
end
