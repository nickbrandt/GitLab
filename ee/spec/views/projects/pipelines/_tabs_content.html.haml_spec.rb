# frozen_string_literal: true

require 'spec_helper'

describe 'projects/pipelines/_tabs_content' do
  set(:user) { create(:user) }
  let(:pipeline) { create(:ci_pipeline).present(current_user: user) }
  let(:locals) { { pipeline: pipeline, project: pipeline.project } }

  before do
    allow(pipeline).to receive(:expose_security_dashboard?).and_return(true)
  end

  shared_examples 'rendering the appropriate API endpoint path' do
    it do
      render partial: 'projects/pipelines/tabs_content', locals: locals

      expect(rendered).to include expected_api_path
    end
  end

  context 'when Vulnerability Findings API enabled' do
    it_behaves_like 'rendering the appropriate API endpoint path' do
      let(:expected_api_path) { "projects/#{pipeline.project_id}/vulnerability_findings" }
    end
  end

  context 'when the Vulnerability Findings API is disabled' do
    before do
      stub_feature_flags(first_class_vulnerabilities: false)
    end

    it_behaves_like 'rendering the appropriate API endpoint path' do
      let(:expected_api_path) { "projects/#{pipeline.project_id}/vulnerabilities" }
    end
  end
end
