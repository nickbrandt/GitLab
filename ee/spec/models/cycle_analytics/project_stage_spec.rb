require 'rails_helper'

describe CycleAnalytics::ProjectStage do
  let(:project) { create(:project, :empty_repo) }
  let(:valid_params) do
    {
      name: 'My Stage',
      project: project,
      start_event_identifier: :issue_created,
      end_event_identifier: :issue_closed
    }
  end

  describe 'validation' do
    it 'is valid' do
      expect(described_class.new(valid_params)).to be_valid
    end

    it 'is invalid when end_event is not allowed for the given start_event' do
      invalid_params = valid_params.merge(
        start_event_identifier: :issue_closed,
        end_event_identifier: :issue_created
      )
      stage = described_class.new(invalid_params)

      expect(stage).not_to be_valid
      expect(stage.errors.details[:end_event]).to eq([{ error: :not_allowed_for_the_given_start_event }])
    end
  end

  describe '#model_to_query' do
    it 'infers the model to be queried from the start event' do
      stage = described_class.new(valid_params)

      expect(stage.model_to_query).to eq(Issue)
    end
  end

  context "relative positioning" do
    it_behaves_like "a class that supports relative positioning" do
      let(:project) { create(:project) }
      let(:factory) { :cycle_analytics_project_stage }
      let(:default_params) { { project: project } }
    end
  end
end
