# frozen_string_literal: true

require 'spec_helper'

describe Projects::V2::CycleAnalyticsStagesController do
  let(:project) { create(:project, :repository) }
  let(:label) { create(:label, project: project) }
  let(:stage_params) do
    {
      name: 'Stage #1',
      start_event: {
        identifier: 'issue_created'
      },
      end_event: {
        identifier: 'issue_label_removed',
        label_id: label.id
      }
    }
  end

  before do
    sign_in(project.creator)
  end

  describe "POST 'create'" do
    it 'creates a new stage' do
      post(:create, params: { project_id: project.name, namespace_id: project.namespace }.merge(stage_params))

      expect(response).to be_created
      expect(json_response["id"]).not_to be_nil
      expect(json_response["name"]).to eq(stage_params[:name])
    end

    it 'returns validation errors' do
      stage_params[:end_event].delete(:label_id)

      post(:create, params: { project_id: project.name, namespace_id: project.namespace }.merge(stage_params))

      expect(response).to be_unprocessable
      expect(json_response["message"]).not_to be_nil
    end
  end

  describe "PUT 'update'" do
    let(:stage) { create(:cycle_analytics_project_stage, project: project) }

    it 'updates a new stage' do
      put(:update, params: { project_id: project.name, namespace_id: project.namespace, id: stage.id }.merge(stage_params))

      expect(response).to be_successful
    end

    it 'returns validation errors' do
      stage_params[:name] = ""

      put(:update, params: { project_id: project.name, namespace_id: project.namespace, id: stage.id }.merge(stage_params))

      expect(response).to be_unprocessable
      expect(json_response["message"]).not_to be_nil
    end
  end

  describe "DELETE 'destroy'" do
    it 'deletes a stage' do
      stage = create(:cycle_analytics_project_stage, project: project)

      delete(:destroy, params: { project_id: project.name, namespace_id: project.namespace, id: stage.id })

      expect(response).to be_successful
      expect(CycleAnalytics::ProjectStage.find_by(id: stage.id)).to be_nil
    end
  end
end
