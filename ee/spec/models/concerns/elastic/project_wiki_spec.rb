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
    expect(project.wiki.search('term1', type: :wiki_blob)[:wiki_blobs][:total_count]).to eq(1)
    expect(project.wiki.search('term1 | term2', type: :wiki_blob)[:wiki_blobs][:total_count]).to eq(2)
  end

  context 'with old indexer' do
    before do
      stub_ee_application_setting(elasticsearch_experimental_indexer: false)
    end

    it 'searches wiki page' do
      expect(project.wiki.search('term1', type: :wiki_blob)[:wiki_blobs][:total_count]).to eq(1)
      expect(project.wiki.search('term1 | term2', type: :wiki_blob)[:wiki_blobs][:total_count]).to eq(2)
    end
  end

  it 'uses the experimental indexer if enabled' do
    stub_ee_application_setting(elasticsearch_experimental_indexer: true)

    expect(project.wiki).not_to receive(:index_blobs)
    expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(project.id, nil, nil, true)

    project.wiki.index_wiki_blobs
  end

  it 'indexes inside Rails if experimental indexer is not enabled' do
    stub_ee_application_setting(elasticsearch_experimental_indexer: false)

    expect(project.wiki).to receive(:index_blobs)
    expect(ElasticCommitIndexerWorker).not_to receive(:perform_async)

    project.wiki.index_wiki_blobs
  end

  it 'can delete wiki pages' do
    expect(project.wiki.search('term2', type: :wiki_blob)[:wiki_blobs][:total_count]).to eq(1)

    Sidekiq::Testing.inline! do
      project.wiki.find_page('omega_page').delete
      last_commit = project.wiki.repository.commit.sha

      expect_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
        expect(indexer).to receive(:run).with(last_commit).and_call_original
      end

      project.wiki.index_wiki_blobs(last_commit)

      Gitlab::Elastic::Helper.refresh_index
    end

    expect(project.wiki.search('term2', type: :wiki_blob)[:wiki_blobs][:total_count]).to eq(0)
  end
end
