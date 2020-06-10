# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::WikiPushService do
  include RepoHelpers

  let(:gl_repository) { "wiki-#{project.id}" }
  let(:key) { create(:key, user: project.owner) }
  let(:key_id) { key.shell_id }
  let(:project) { create(:project, :repository, :wiki_repo) }
  let(:post_received) { ::Gitlab::GitPostReceive.new(project, key_id, changes, {}) }

  before do
    allow(post_received).to receive(:identify).and_return(project.owner)
  end

  context 'when elasticsearch is enabled' do
    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    end

    describe 'when changes include master ref' do
      let(:changes) { +"123456 789012 refs/heads/tést\n654321 210987 refs/tags/tag\n423423 797823 refs/heads/master" }

      before do
        allow(project.wiki.repository.raw).to receive(:raw_changes_between).once.with('423423', '797823').and_return([])
      end

      it 'triggers a wiki update' do
        expect(project.wiki).to receive(:index_wiki_blobs)

        described_class.new(project, project.owner, changes: post_received.changes).execute
      end
    end

    describe 'when changes do not include master ref' do
      let(:changes) { +"123456 789012 refs/heads/tést\n654321 210987 refs/tags/tag" }

      it 'does not trigger a wiki update' do
        expect(project.wiki).not_to receive(:index_wiki_blobs)

        described_class.new(project, project.owner, changes: post_received.changes).execute
      end
    end
  end

  context 'when elasticsearch is disabled' do
    before do
      stub_ee_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
      allow(project.wiki.repository.raw).to receive(:raw_changes_between).once.with('423423', '797823').and_return([])
    end

    describe 'when changes include master ref' do
      let(:changes) { +"123456 789012 refs/heads/tést\n654321 210987 refs/tags/tag\n423423 797823 refs/heads/master" }

      it 'does nothing even if changes include master ref' do
        expect(project.wiki).not_to receive(:index_wiki_blobs)

        described_class.new(project, project.owner, changes: post_received.changes).execute
      end
    end
  end
end
