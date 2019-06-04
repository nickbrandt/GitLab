require 'spec_helper'

describe Resolvers::IssueAssigneesResolver do
  include GraphqlHelpers

  let(:current_user) { create(:user) }

  context "with an issue" do
    set(:assignee1) { create(:user) }
    set(:assignee2) { create(:user) }
    set(:issue) { create(:issue, state: :opened, assignees: [assignee1, assignee2]) }

    describe '#resolve' do
      it 'finds all issue assignees' do
        expect(resolve_assignees).to contain_exactly(assignee1, assignee2)
      end

      it 'filters by username' do
        expect(resolve_assignees(username: assignee2.username)).to contain_exactly(assignee2)
      end

      it 'sort assignees' do
        expect(resolve_assignees(sort: 'created_desc')).to eq [assignee2, assignee1]
      end
    end
  end

  def resolve_assignees(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: issue, args: args, ctx: context)
  end
end
