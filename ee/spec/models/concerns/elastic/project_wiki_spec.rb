# frozen_string_literal: true

require 'spec_helper'

describe ProjectWiki, :elastic do
  set(:project) { create(:project, :wiki_repo) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    Sidekiq::Testing.inline! do
      project.wiki.create_page("index_page", "Bla bla term1")
      project.wiki.create_page("omega_page", "Bla bla term2")
      project.wiki.index_wiki_blobs

      Gitlab::Elastic::Helper.refresh_index
    end
  end

  it "searches wiki page" do
    expect(project.wiki.elastic_search('term1', type: :wiki_blob)[:wiki_blobs][:total_count]).to eq(1)
    expect(project.wiki.elastic_search('term1 | term2', type: :wiki_blob)[:wiki_blobs][:total_count]).to eq(2)
  end

  it 'indexes' do
    expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(project.id, nil, nil, true)

    project.wiki.index_wiki_blobs
  end

  it 'can delete wiki pages' do
    expect(project.wiki.elastic_search('term2', type: :wiki_blob)[:wiki_blobs][:total_count]).to eq(1)

    Sidekiq::Testing.inline! do
      project.wiki.find_page('omega_page').delete
      last_commit = project.wiki.repository.commit.sha

      expect_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
        expect(indexer).to receive(:run).with(last_commit).and_call_original
      end

      project.wiki.index_wiki_blobs(last_commit)

      Gitlab::Elastic::Helper.refresh_index
    end

    expect(project.wiki.elastic_search('term2', type: :wiki_blob)[:wiki_blobs][:total_count]).to eq(0)
  end
end
