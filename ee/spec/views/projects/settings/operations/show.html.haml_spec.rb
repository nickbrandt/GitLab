# frozen_string_literal: true

require 'spec_helper'

describe 'projects/settings/operations/show' do
  let(:project) { create(:project, :repository) }

  before do
    assign(:project, project)
    assign(:repository, project.repository)
    allow(view).to receive(:current_ref).and_return('master')

    stub_licensed_features(tracing: true)
  end

  describe 'Operations > Tracing' do
    context 'with project.tracing_external_url' do
      let(:tracing_url) { 'https://tracing.url' }
      let(:tracing_settings) { create(:project_tracing_setting, project: project, external_url: tracing_url) }

      before do
        allow(view).to receive(:can?).and_return(true)

        assign(:tracing_settings, tracing_settings)
      end

      it 'links to project.tracing_external_url' do
        render

        expect(rendered).to have_link('Tracing', href: tracing_url)
      end

      context 'with malicious external_url' do
        let(:malicious_tracing_url) { "https://replaceme.com/'><script>alert(document.cookie)</script>" }
        let(:cleaned_url) { "https://replaceme.com/'>" }

        before do
          tracing_settings.update_column(:external_url, malicious_tracing_url)
        end

        it 'sanitizes external_url' do
          render

          expect(tracing_settings.external_url).to eq(malicious_tracing_url)
          expect(rendered).to have_link('Tracing', href: cleaned_url)
        end
      end
    end

    context 'without project.tracing_external_url' do
      let(:tracing_settings) { build(:project_tracing_setting, project: project) }

      before do
        allow(view).to receive(:can?).and_return(true)

        tracing_settings.external_url = nil

        assign(:tracing_settings, tracing_settings)
      end

      it 'links to Tracing page' do
        render

        expect(rendered).to have_link('Tracing', href: project_tracing_path(project))
      end
    end
  end
end
