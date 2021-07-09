# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ComplianceViolation, type: :model do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:merge_request) { create(:merge_request) }

  describe "Associations" do
    it { is_expected.to belong_to(:violating_user) }
    it { is_expected.to belong_to(:merge_request) }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:violating_user_id) }
    it { is_expected.to validate_presence_of(:merge_request_id) }
  end

  describe "Enums" do
    it { is_expected.to define_enum_for(:reason) }
  end

  describe '.process_merge_request' do
    subject { described_class.process_merge_request(merge_request) }

    where(:approved_by_committer, :approved_by_author, :approved_by_insufficient_users, :count) do
      true                | true                | true | 3
    end

    with_them do
      subject { described_class.process_merge_request(merge_request) }

      before do
        allow(merge_request).to receive(:approved_by_committer?).and_return(approved_by_committer)
        allow(merge_request).to receive(:approved_by_author?).and_return(approved_by_author)
        allow(merge_request).to receive(:approved_by_insufficient_users?).and_return(approved_by_insufficient_users)
      end

      it 'creates the correct number of violations' do

        expect { subject }.to change { merge_request.compliance_violations.count }.by(count)
      end
    end
  end
end
