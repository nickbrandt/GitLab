# frozen_string_literal: true

require 'spec_helper'

describe Mutations::MergeRequests::SetAssignees do
  let(:merge_request) { create(:merge_request) }
  let(:user) { create(:user) }
  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }) }

  describe '#resolve' do
    let(:assignees) { create_list(:user, 3) }
    let(:assignee_usernames) { assignees.map(&:username) }
    let(:mutated_merge_request) { subject[:merge_request] }
    subject { mutation.resolve(project_path: merge_request.project.full_path, iid: merge_request.iid, assignee_usernames: assignee_usernames) }

    before do
      assignees.each do |user|
        merge_request.project.add_developer(user)
      end
    end

    context 'when the user can update the merge request' do
      before do
        merge_request.project.add_developer(user)
      end

      it 'sets merge request assignees' do
        expect(mutated_merge_request).to eq(merge_request)
        expect(mutated_merge_request.assignees).to match_array(assignees)
        expect(subject[:errors]).to be_empty
      end

      it 'removes assignees not in the list' do
        users = create_list(:user, 2)
        users.each do |user|
          merge_request.project.add_developer(user)
        end
        merge_request.assignees = users
        merge_request.save!

        expect(mutated_merge_request).to eq(merge_request)
        expect(mutated_merge_request.assignees).to match_array(assignees)
        expect(subject[:errors]).to be_empty
      end

      context 'when passing "append" as true' do
        subject { mutation.resolve(project_path: merge_request.project.full_path, iid: merge_request.iid, assignee_usernames: assignee_usernames, operation_mode: Types::MutationOperationModeEnum.enum[:append]) }

        let(:existing_assignees) { create_list(:user, 2) }

        before do
          existing_assignees.each do |user|
            merge_request.project.add_developer(user)
          end
          merge_request.assignees = existing_assignees
          merge_request.save!
        end

        it 'does not remove assignees not in the list' do
          expect(mutated_merge_request).to eq(merge_request)
          expect(mutated_merge_request.assignees).to match_array(assignees + existing_assignees)
          expect(subject[:errors]).to be_empty
        end
      end
    end
  end
end
