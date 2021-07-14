# frozen_string_literal: true

RSpec.describe Ci::BuildCancelService do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  describe '#execute' do
    subject(:execute) { described_class.new(build).execute }

    context 'when build is cancelable' do
      let!(:build) { create(:ci_build, :cancelable, pipeline: pipeline) }

      it 'transits build to canceled', :aggregate_failures do
        response = execute

        expect(response).to be_success
        expect(response.payload.reload).to be_canceled
      end
    end

    context 'when build is not cancelable' do
      let!(:build) { create(:ci_build, :canceled, pipeline: pipeline) }

      it 'responds with unprocessable entity', :aggregate_failures do
        response = execute

        expect(response).to be_error
        expect(response.http_status).to eq(:unprocessable_entity)
      end
    end
  end
end
