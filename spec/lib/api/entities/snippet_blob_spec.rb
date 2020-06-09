# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Entities::SnippetBlob do
  let_it_be(:personal_snippet) { create(:personal_snippet, :repository) }
  let_it_be(:project_snippet)  { create(:project_snippet, :repository) }

  let(:blob)   { snippet.blobs.first }
  let(:entity) { described_class.new(blob) }
  let(:ref)    { blob.repository.root_ref }

  subject { entity.as_json }

  context 'with PersonalSnippet blob' do
    let(:snippet) { personal_snippet }

    it { expect(subject[:path]).to eq blob.path }
    it { expect(subject[:raw_url]).to match("/-/snippets/#{snippet.id}/raw/#{ref}/#{blob.path}") }
  end

  context 'with ProjectSnippet blob' do
    let(:snippet) { project_snippet }

    it { expect(subject[:path]).to eq blob.path }
    it { expect(subject[:raw_url]).to match("#{snippet.project.full_path}/-/snippets/#{snippet.id}/raw/#{ref}/#{blob.path}") }
  end
end
