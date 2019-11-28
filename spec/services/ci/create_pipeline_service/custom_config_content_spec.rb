# frozen_string_literal: true
require 'spec_helper'

describe Ci::CreatePipelineService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:admin) }
  let(:ref) { 'refs/heads/master' }
  let(:service) { described_class.new(project, user, { ref: ref }) }
  let(:pipeline) { service.execute(:push, config_content: config_content) }

  context 'custom config content' do
    let(:config_content) do
      YAML.dump(
        rspec: { script: 'rspec' },
        custom: { script: 'custom' }
      )
    end

    it 'creates a pipeline using the content passed in as param' do
      expect(pipeline).to be_persisted
      expect(pipeline.builds.map(&:name)).to eq %w[rspec custom]
      expect(pipeline.config_source).to eq 'bridge_source'
    end
  end
end
