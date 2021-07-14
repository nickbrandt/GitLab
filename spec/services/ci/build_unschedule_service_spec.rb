# frozen_string_literal: true

RSpec.describe Ci::BuildUnscheduleService do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  describe '#execute' do
    subject(:execute) { described_class.new(build).execute }

    context 'when build is scheduled' do
      let!(:build) { create(:ci_build, :scheduled, pipeline: pipeline) }

      it 'transits build to manual' do
        response = execute

        expect(response).to be_success
        expect(response.payload.reload).to be_manual
      end
    end

    context 'when build is not scheduled' do
      let!(:build) { create(:ci_build, pipeline: pipeline) }

      it 'responds with unprocessable entity', :aggregate_failures do
        response = execute

        expect(response).to be_error
        expect(response.http_status).to eq(:unprocessable_entity)
      end
    end
  end
end
