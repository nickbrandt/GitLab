# frozen_string_literal: true

require 'spec_helper'

describe API::Helpers::IssuesHelpers do
  set(:group) { create(:group) }
  set(:project) { create(:project, group: group) }
  set(:user) { create(:user) }
  set(:epic) { create(:epic, group: group) }

  subject(:issues_helpers) { Class.new.include(described_class).new }

  before do
    allow(issues_helpers).to receive(:current_user).and_return(user)

    group.add_owner(user)
  end

  describe 'find_issues' do
    context 'with epics' do
      before do
        allow(issues_helpers).to receive(:declared_params).and_return(project_id: project.id)
      end

      it 'returns results' do
        issues = create_issues(2, project: project, epic: epic)

        expect(issues_helpers.find_issues.count).to be(issues.count)
      end

      it 'avoids N+1 queries' do
        create_issues(2, project: project, epic: epic)

        recorder = ActiveRecord::QueryRecorder.new { issues_helpers.find_issues.map(&:epic) }

        create_issues(4, project: project, epic: epic)

        expect { issues_helpers.find_issues.map(&:epic) }.not_to exceed_query_limit(recorder)
      end
    end
  end

  private

  def create_issues(count, params)
    (1..count).step do
      create(:issue, params)
    end
  end
end
