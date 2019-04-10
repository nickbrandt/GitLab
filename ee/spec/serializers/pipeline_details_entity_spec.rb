# frozen_string_literal: true

require 'spec_helper'

describe PipelineDetailsEntity do
  let(:user) { create(:user) }
  let(:request) { double('request') }

  before do
    stub_not_protect_default_branch

    allow(request).to receive(:current_user).and_return(user)
  end

  let(:entity) do
    described_class.represent(pipeline, request: request)
  end

  describe '#as_json' do
    subject { entity.as_json }

    context 'when pipeline is triggered by other pipeline' do
      let(:pipeline) { create(:ci_empty_pipeline) }

      before do
        create(:ci_sources_pipeline, pipeline: pipeline)
      end

      it 'contains an information about depedent pipeline' do
        expect(subject[:triggered_by]).to be_a(Hash)
        expect(subject[:triggered_by][:path]).not_to be_nil
        expect(subject[:triggered_by][:details]).not_to be_nil
        expect(subject[:triggered_by][:details][:status]).not_to be_nil
        expect(subject[:triggered_by][:project]).not_to be_nil
      end
    end

    context 'when pipeline triggered other pipeline' do
      let(:pipeline) { create(:ci_empty_pipeline) }
      let(:build) { create(:ci_build, pipeline: pipeline) }

      before do
        create(:ci_sources_pipeline, source_job: build)
        create(:ci_sources_pipeline, source_job: build)
      end

      it 'contains an information about depedent pipeline' do
        expect(subject[:triggered]).to be_a(Array)
        expect(subject[:triggered].length).to eq(2)
        expect(subject[:triggered].first[:path]).not_to be_nil
        expect(subject[:triggered].first[:details]).not_to be_nil
        expect(subject[:triggered].first[:details][:status]).not_to be_nil
        expect(subject[:triggered].first[:project]).not_to be_nil
      end
    end
  end
end
