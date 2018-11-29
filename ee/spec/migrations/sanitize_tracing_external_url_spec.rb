# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('ee', 'db', 'post_migrate', '20181116100917_sanitize_tracing_external_url.rb')

describe SanitizeTracingExternalUrl, :migration do
  let(:migration) { described_class.new }

  describe '#up' do
    let(:projects) { table(:projects) }
    let(:namespaces) { table(:namespaces) }
    let(:project_tracing_settings) { table(:project_tracing_settings) }

    let(:valid_url) { "https://replaceme.com/" }
    let(:invalid_url) { "https://replaceme.com/'><script>alert(document.cookie)</script>" }
    let(:cleaned_url) { "https://replaceme.com/'>" }

    before do
      namespaces.create(id: 1, name: 'gitlab-org', path: 'gitlab-org')
      projects.create!(id: 123, name: 'gitlab1', path: 'gitlab1', namespace_id: 1)
      projects.create!(id: 124, name: 'gitlab2', path: 'gitlab2', namespace_id: 1)
      project_tracing_settings.create!(id: 2234, external_url: invalid_url, project_id: 123)
      project_tracing_settings.create!(id: 2235, external_url: valid_url, project_id: 124)
    end

    it 'correctly sanitizes project_tracing_settings external_url' do
      migrate!

      expect(project_tracing_settings.order(:id).pluck(:external_url)).to match_array([cleaned_url, valid_url])
    end
  end
end
