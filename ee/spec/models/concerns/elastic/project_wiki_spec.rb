# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectWiki, :elastic do
  let(:project) { create(:project, :wiki_repo) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    Sidekiq::Testing.inline! do
      project.wiki.create_page("index_page", "Bla bla term1")
      project.wiki.create_page("omega_page", "Bla bla term2")
      project.wiki.index_wiki_blobs

      ensure_elasticsearch_index!
    end
  end

  it "searches wiki page" do
    expect(project.wiki.elastic_search('term1', type: 'wiki_blob')[:wiki_blobs][:total_count]).to eq(1)
    expect(project.wiki.elastic_search('term1 | term2', type: 'wiki_blob')[:wiki_blobs][:total_count]).to eq(2)
  end

  it 'can delete wiki pages', :sidekiq_inline do
    expect(project.wiki.elastic_search('term2', type: 'wiki_blob')[:wiki_blobs][:total_count]).to eq(1)

    project.wiki.find_page('omega_page').delete
    project.wiki.index_wiki_blobs
    ensure_elasticsearch_index!

    expect(project.wiki.elastic_search('term2', type: 'wiki_blob')[:wiki_blobs][:total_count]).to eq(0)
  end
end
