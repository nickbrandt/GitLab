# frozen_string_literal: true

require 'spec_helper'

describe Projects::V2::CycleAnalyticsRecordsController do
  let(:project) { create(:project, :empty_repo) }
  let(:stage) { create(:cycle_analytics_project_stage, :between_issue_created_and_issue_closed, project: project) }

  before do
    sign_in(project.creator)
  end

  describe "GET 'index'" do
    it 'renders serialized records' do
      issue = Timecop.travel(Time.new(2019, 6, 1)) do
        issue = create(:issue, project: project)
        issue.close!
        issue
      end

      get(:index, params: {
        project_id: project.name,
        namespace_id: project.namespace,
        stage_id: stage.id,
        start_date: '2019-01-01'
      })

      expect(response).to be_successful
      expect(json_response.size).to eq(1)
      expect(json_response.first["title"]).to eq(issue.title)
    end
  end
end
