# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::UpdateAssignedOpenIssueCountService do
  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  describe '#initialize' do
    context 'incorrect arguments provided' do
      it 'raises an error if there is no user' do
        expect { described_class.new(current_user: nil, target_user: other_user) }.to raise_error(ArgumentError, /Please provide a user/)
        expect { described_class.new(current_user: "nonsense", target_user: other_user) }.to raise_error(ArgumentError, /Please provide a user/)
      end

      it 'raises an error if there are no target user' do
        expect { described_class.new(current_user: user, target_user: nil) }.to raise_error(ArgumentError, /Please provide a target user/)
        expect { described_class.new(current_user: user, target_user: "nonsense") }.to raise_error(ArgumentError, /Please provide a target user/)
      end
    end

    context 'when correct arguments provided' do
      it 'does not error when user and target are different' do
        expect { described_class.new(current_user: user, target_user: other_user) }.not_to raise_error
      end

      it 'does not error when user and target are the same' do
        expect { described_class.new(current_user: user, target_user: user) }.not_to raise_error
      end
    end
  end

  describe "#execute", :clean_gitlab_redis_cache do
    let(:fake_update_service) { double }
    let(:fake_issue_count_service) { double }
    let(:provided_value) { nil }

    subject { described_class.new(current_user: user, target_user: other_user, params: { count_to_persist: provided_value }).execute }

    context 'successful' do
      it 'returns a success response' do
        expect(subject).to be_success
      end

      it 'deletes the cache' do
        expect(Rails.cache).to receive(:delete).with(['users', other_user.id, 'assigned_open_issues_count'])

        subject
      end

      it 'writes the cache with the new value' do
        expect(Rails.cache).to receive(:write).with(['users', other_user.id, 'assigned_open_issues_count'], 0, expires_in: other_user.count_cache_validity_period)

        subject
      end

      it 'calls the User::Update service to persist the value' do
        expect(Users::UpdateService).to receive(:new).with(user, user: other_user, assigned_open_issues_count: 0).and_return(fake_update_service)
        expect(fake_update_service).to receive(:execute)

        subject
      end

      context 'when a value is provided' do
        let(:provided_value) { 4 }

        it 'does not recalculate' do
          expect(IssuesFinder).not_to receive(:new).with(other_user, assignee_id: other_user.id, state: 'opened', non_archived: true)

          subject
        end
      end

      context 'when a value is NOT provided' do
        it 'calls the issues finder to get the latest value' do
          expect(IssuesFinder).to receive(:new).with(other_user, assignee_id: other_user.id, state: 'opened', non_archived: true).and_return(fake_issue_count_service)
          expect(fake_issue_count_service).to receive(:execute)

          subject
        end
      end

    end
  end
end
