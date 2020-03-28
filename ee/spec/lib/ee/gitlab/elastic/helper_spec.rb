# frozen_string_literal: true

require 'fast_spec_helper'
require 'webmock/rspec'

describe Gitlab::Elastic::Helper do
  describe '.index_exists' do
    it 'returns correct values' do
      described_class.create_empty_index

      expect(described_class.index_exists?).to eq(true)

      described_class.delete_index

      expect(described_class.index_exists?).to eq(false)
    end
  end

  describe 'reindex_to_another_cluster' do
    it 'creates an empty index and triggers a reindex' do
      _version_check_request = stub_request(:get, 'http://newcluster.example.com:9200/')
        .to_return(status: 200, body: { version: { number: '7.5.1' } }.to_json)

      _index_exists_check = stub_request(:head, 'http://newcluster.example.com:9200/gitlab-test')
        .to_return(status: 404, body: +'')

      create_cluster_request = stub_request(:put, 'http://newcluster.example.com:9200/gitlab-test')
        .to_return(status: 200, body: +'')

      optimize_settings_for_write_request = stub_request(:put, 'http://newcluster.example.com:9200/gitlab-test/_settings')
        .with(body: { index: { number_of_replicas: 0, refresh_interval: "-1" } })
        .to_return(status: 200, body: +'')

      reindex_request = stub_request(:post, 'http://newcluster.example.com:9200/_reindex?wait_for_completion=false')
        .with(
          body: {
            source: {
              remote: {
                host: 'http://oldcluster.example.com:9200/',
                username: 'olduser',
                password: 'oldpass'
              },
              index: 'gitlab-test'
            },
            dest: {
              index: 'gitlab-test'
            }
          }).to_return(status: 200,
                       headers: { "Content-Type" => "application/json" },
                       body: { task: 'abc123' }.to_json)

      source_url = 'http://olduser:oldpass@oldcluster.example.com:9200/'
      dest_url = 'http://newcluster.example.com:9200/'

      task = Gitlab::Elastic::Helper.reindex_to_another_cluster(source_url, dest_url)
      expect(task).to eq('abc123')

      assert_requested create_cluster_request
      assert_requested optimize_settings_for_write_request
      assert_requested reindex_request
    end
  end
end
