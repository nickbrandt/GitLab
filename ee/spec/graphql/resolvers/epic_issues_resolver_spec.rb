# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::EpicIssuesResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project1) { create(:project, :public, group: group) }
  let_it_be(:project2) { create(:project, :private, group: group) }
  let_it_be(:epic1) { create(:epic, group: group) }
  let_it_be(:epic2) { create(:epic, group: group) }
  let_it_be(:issue1) { create(:issue, project: project1) }
  let_it_be(:issue2) { create(:issue, project: project1) }
  let_it_be(:issue3) { create(:issue, project: project2) }
  let_it_be(:epic_issue1) { create(:epic_issue, epic: epic1, issue: issue1, relative_position: 3) }
  let_it_be(:epic_issue2) { create(:epic_issue, epic: epic1, issue: issue2, relative_position: 2) }
  let_it_be(:epic_issue3) { create(:epic_issue, epic: epic2, issue: issue3, relative_position: 1) }

  before do
    group.add_developer(current_user)
    stub_licensed_features(epics: true)
  end

  describe '#resolve' do
    it 'finds all epic issues' do
      result = batch_sync(max_queries: 4) { resolve_epic_issues(epic1) }

      expect(result).to contain_exactly(issue1, issue2)
    end

    it 'can batch-resolve epic issues from different epics' do
      result = batch_sync(max_queries: 4) do
        [resolve_epic_issues(epic1), resolve_epic_issues(epic2)]
      end

      expect(result).to contain_exactly([issue1, issue2], [issue3])
    end
  end

  def resolve_epic_issues(object, args = {}, context = { current_user: current_user })
    resolve(described_class, obj: object, args: args, ctx: context)
  end
end
