# frozen_string_literal: true

require 'spec_helper'

describe CycleAnalytics::StageCreateService do
  let(:project) { create(:project, :empty_repo) }
  let(:label) { create(:label, project: project, title: 'My Label') }
  let(:valid_params) do
    {
      name: 'my awesome stage',
      start_event: {
        identifier: :issue_created
      },
      end_event: {
        identifier: :issue_first_mentioned_in_commit
      }
    }
  end

  it 'creates a stage' do
    stage = described_class.new(parent: project, params: valid_params).execute

    expect(stage).to be_persisted
    expect(stage.start_event).to be_a_kind_of(Gitlab::CycleAnalytics::StageEvents::IssueCreated)
    expect(stage.end_event).to be_a_kind_of(Gitlab::CycleAnalytics::StageEvents::IssueFirstMentionedInCommit)
  end

  it 'handles adding label based event' do
    valid_params[:start_event] = {
      identifier: :issue_label_added,
      label_id: label.id
    }

    stage = described_class.new(parent: project, params: valid_params).execute

    expect(stage).to be_persisted
    start_event = stage.start_event
    expect(start_event).to be_a_kind_of(Gitlab::CycleAnalytics::StageEvents::IssueLabelAdded)
    expect(start_event.label).to eq(label)
  end

  describe 'returns the invalid model in case of validation error' do
    it 'when the events are incompatible' do
      params = {
        name: 'my awesome stage',
        start_event: {
          identifier: :issue_created
        },
        end_event: {
          identifier: :merge_request_last_edited
        }
      }

      stage = described_class.new(parent: project, params: params).execute

      expect(stage).to be_invalid
    end

    it 'when the event model has validation errors' do
      params = {
        name: 'my awesome stage',
        start_event: {
          identifier: :issue_created
        },
        end_event: {
          identifier: :issue_label_added # label_id is missing
        }
      }

      stage = described_class.new(parent: project, params: params).execute

      expect(stage).to be_invalid
    end
  end
end
