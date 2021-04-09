# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Ci::PipelineEditorHelper do
  let_it_be(:project) { create(:project, :public, :repository) }

  describe '#js_pipeline_editor_data' do
    before do
      stub_licensed_features(api_fuzzing: true)

      allow(helper)
        .to receive(:namespace_project_new_merge_request_path)
        .and_return('/mock/project/-/merge_requests/new')

      allow(helper)
        .to receive(:image_path)
        .and_return('foo')
    end

    subject(:pipeline_editor_data) { helper.js_pipeline_editor_data(project) }

    it 'returns ee specific values' do
      expect(pipeline_editor_data.keys).to include('api-fuzzing-configuration-path')
    end
  end
end
