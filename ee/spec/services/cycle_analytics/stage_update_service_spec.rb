# frozen_string_literal: true

require 'spec_helper'

describe CycleAnalytics::StageUpdateService do
  let(:project) { create(:project, :empty_repo) }
  let(:default_stages) { Gitlab::CycleAnalytics::DefaultStages.all }

  describe 'updating the visibility of a default stage' do
    let(:stage) do
      project.cycle_analytics_stages << CycleAnalytics::ProjectStage.new(default_stages.first)
      project.cycle_analytics_stages.first
    end

    it 'hides the stage' do
      described_class.new(stage: stage, params: { hidden: true }).execute

      expect(stage).to be_valid
      expect(stage.hidden).to eq(true)
    end

    it 'shows the stage' do
      stage.update!(hidden: true)

      described_class.new(stage: stage, params: { hidden: false }).execute

      expect(stage).to be_valid
      expect(stage.hidden).to eq(false)
    end
  end

  describe 'updating a custom stage' do
    let(:label) { create(:label, project: project) }
    let(:stage) do
      create(:cycle_analytics_project_stage, {
        project: project,
        start_event_identifier: :issue_created,
        end_event_identifier: :issue_closed
      })
    end

    it 'succeeds' do
      params = {
        start_event: {
          identifier: :issue_created
        },
        end_event: {
          identifier: :issue_label_removed,
          label_id: label.id
        }
      }

      described_class.new(stage: stage, params: params).execute

      expect(stage).to be_valid
      event = stage.end_event
      expect(event).to be_a_kind_of(Gitlab::CycleAnalytics::StageEvents::IssueLabelRemoved)
      expect(event.label).to eq(label)
    end

    it 'clears start_event_label_id attribute if event changes' do
      stage.update!(end_event_identifier: :issue_label_removed, end_event_label_id: label.id)

      params = {
        start_event: {
          identifier: :issue_created
        },
        end_event: {
          identifier: :issue_closed
        }
      }

      described_class.new(stage: stage, params: params).execute

      expect(stage).to be_valid
      expect(stage.end_event_label_id).to be_nil
    end
  end

  describe 'positioning' do
    it 'moving an item to the bottom' do
      stage_to_move = create(:cycle_analytics_project_stage, project: project, relative_position: 1)
      create(:cycle_analytics_project_stage, project: project, relative_position: 2)
      last_stage = create(:cycle_analytics_project_stage, project: project, relative_position: 3)

      described_class.new(stage: stage_to_move, params: { move_after_id: last_stage.id }).execute

      stages = project.cycle_analytics_stages.ordered
      expect(stages.last).to eq(stage_to_move)
    end

    it 'moving an item to the middle' do
      create(:cycle_analytics_project_stage, project: project, relative_position: 1)
      middle_stage = create(:cycle_analytics_project_stage, project: project, relative_position: 2)
      stage_to_move = create(:cycle_analytics_project_stage, project: project, relative_position: 3)

      described_class.new(stage: stage_to_move, params: { move_before_id: middle_stage.id }).execute

      _, middle, last = project.cycle_analytics_stages.ordered
      expect(middle).to eq(stage_to_move)
      expect(last).to eq(middle_stage)
    end
  end
end
