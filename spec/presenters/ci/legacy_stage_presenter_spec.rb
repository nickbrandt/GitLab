# frozen_string_literal: true

require 'spec_helper'

describe Ci::LegacyStagePresenter do
  let(:legacy_stage) { create(:ci_stage) }

  describe '#preloaded_statuses' do
    subject(:preloaded_statuses) { described_class.new(legacy_stage).preloaded_statuses }

    let!(:build) { create(:ci_build, :tags, pipeline: legacy_stage.pipeline, stage: legacy_stage.name) }

    before do
      create(:generic_commit_status, pipeline: legacy_stage.pipeline, stage: legacy_stage.name)
    end

    it 'preloads build tags' do
      expect(preloaded_statuses.first.association(:tags)).to be_loaded
    end
  end
end
