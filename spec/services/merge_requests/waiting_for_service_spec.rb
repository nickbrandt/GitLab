# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::WaitingForService do
  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:user3) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request) }

  let(:project) { merge_request.project }

  subject(:service) { described_class.new(merge_request) }

  describe '#wait_for' do
    where(:requestee, :requester, :expected_outcomea) do
      user1 | user2 | user1
    end

    with_them do
    end

    context 'when adding a new user to wait list' do
      it 'adds requestee to the waiting for list' do
        service.wait_for(user1, user2)

        expect(service.pending_users).to eq([user1])
      end

      context 'without the requester' do
        it 'adds requestee to the waiting for list' do
          service.wait_for(user1, nil)

          expect(service.pending_users).to eq([user1])
        end
      end
    end

    context 'when adding an existing user to wait list' do
      before do
        service.wait_for(user1, user2)
      end

      context 'with the same requester' do
        it 'does not add requestee to the waiting for list' do
          service.wait_for(user1, user2)

          expect(service.pending_users).to eq([user1])
        end
      end

      context 'with the different requester' do
        it 'add requestee to the waiting for list' do
          service.wait_for(user1, user3)

          expect(service.pending_users).to eq([user1, user1])
        end
      end
    end

    context 'when adding existing user to wait list with' do
      before do
        service.wait_for(user1, user2)
      end

      it 'does not add requestee to the waiting for list' do
        service.wait_for(user1, user2)

        expect(service.pending_users).to eq([user1])
      end
    end
  end

  describe '#mark_as_done' do
    context 'when removing a new user to wait list' do
      it 'removes requestee from the waiting for list' do
        service.mark_as_done(user1, user2)

        expect(service.pending_users).to eq([])
      end
    end
  end
end
