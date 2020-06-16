# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GlRepository::Identifier do
  let_it_be(:project) { create(:project) }
  let_it_be(:personal_snippet) { create(:personal_snippet, author: project.owner) }
  let_it_be(:project_snippet) { create(:project_snippet, project: project, author: project.owner) }

  describe 'project repository' do
    it_behaves_like 'parsing gl_repository identifier' do
      let(:record_id) { project.id }
      let(:identifier) { "project-#{record_id}" }
      let(:expected_container) { project }
      let(:expected_type) { Gitlab::GlRepository::PROJECT }
    end
  end

  describe 'wiki' do
    it_behaves_like 'parsing gl_repository identifier' do
      let(:record_id) { project.id }
      let(:identifier) { "wiki-#{record_id}" }
      let(:expected_container) { project }
      let(:expected_type) { Gitlab::GlRepository::WIKI }
    end
  end

  describe 'snippet' do
    context 'when PersonalSnippet' do
      it_behaves_like 'parsing gl_repository identifier' do
        let(:record_id) { personal_snippet.id }
        let(:identifier) { "snippet-#{record_id}" }
        let(:expected_container) { personal_snippet }
        let(:expected_type) { Gitlab::GlRepository::SNIPPET }
      end
    end

    context 'when ProjectSnippet' do
      it_behaves_like 'parsing gl_repository identifier' do
        let(:record_id) { project_snippet.id }
        let(:identifier) { "snippet-#{record_id}" }
        let(:expected_container) { project_snippet }
        let(:expected_type) { Gitlab::GlRepository::SNIPPET }
      end
    end
  end

  describe 'design' do
    it_behaves_like 'parsing gl_repository identifier' do
      let(:record_id) { project.id }
      let(:identifier) { "design-#{project.id}" }
      let(:expected_container) { project }
      let(:expected_type) { Gitlab::GlRepository::DESIGN }
    end
  end

  context 'when the format is incorrect' do
    where(:identifier) do
      [
        'wiki-noid',
        'foo-2',
        'snippet-2-wiki',
        'snippet',
        'project-1-wiki-bar'
      ]
    end

    with_them do
      it_behaves_like 'illegal gl_identifier'
    end
  end
end
