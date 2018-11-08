# frozen_string_literal: true

require 'spec_helper'

describe 'layouts/nav/sidebar/_project' do
  let(:project) { create(:project, :repository) }

  before do
    assign(:project, project)
    assign(:repository, project.repository)
    allow(view).to receive(:current_ref).and_return('master')

    stub_licensed_features(tracing: true)
  end

  describe 'Operations > Tracing' do
    it 'is not visible when no valid license' do
      allow(view).to receive(:can?).and_return(true)
      stub_licensed_features(tracing: false)

      render

      expect(rendered).not_to have_text 'Tracing'
    end

    it 'is not visible to unauthorized user' do
      render

      expect(rendered).not_to have_text 'Tracing'
    end

    context 'with project.tracing_external_url' do
      let(:tracing_url) { 'https://tracing.url' }

      before do
        allow(view).to receive(:can?).and_return(true)

        allow(project).to receive(:tracing_external_url).and_return(tracing_url)
      end

      it 'links to project.tracing_external_url' do
        render

        expect(rendered).to have_link('Tracing', href: tracing_url)
      end
    end

    context 'without project.tracing_external_url' do
      before do
        allow(view).to receive(:can?).and_return(true)

        allow(project).to receive(:tracing_external_url).and_return(nil)
      end

      it 'links to Tracing page' do
        render

        expect(rendered).to have_link('Tracing', href: project_tracing_path(project))
      end
    end
  end

  describe 'Settings > Operations' do
    it 'is not visible when no valid license' do
      allow(view).to receive(:can?).and_return(true)
      stub_licensed_features(tracing: false)

      render

      expect(rendered).not_to have_link project_settings_operations_path(project)
    end

    it 'is not visible to unauthorized user' do
      render

      expect(rendered).not_to have_link project_settings_operations_path(project)
    end

    it 'links to settings page' do
      allow(view).to receive(:can?).and_return(true)

      render

      expect(rendered).to have_link('Operations', href: project_settings_operations_path(project))
    end
  end
end
