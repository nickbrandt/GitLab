require 'rails_helper'

describe Ci::BuildPresenter do
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:build) { create(:ci_build, pipeline: pipeline) }

  subject(:presenter) do
    described_class.new(build)
  end

  describe '#callout_failure_message' do
    let(:build) { create(:ci_build_environment_failure) }

    it 'returns a verbose failure reason' do
      description = subject.callout_failure_message
      expect(description).to eq('The environment this job is deploying to is protected. Only users with permission may successfully run this job')
    end
  end
end
