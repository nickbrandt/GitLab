# frozen_string_literal: true

module Gitlab
  module Elastic
    class Helper
      # rubocop: disable CodeReuse/ActiveRecord
      def self.create_empty_index(version = ::Elastic::MultiVersionUtil::TARGET_VERSION)
        settings = {}
        mappings = {}

        [
          Project,
          Issue,
          MergeRequest,
          Snippet,
          Note,
          Milestone,
          ProjectWiki,
          Repository
        ].each do |klass|
          settings.deep_merge!(klass.__elasticsearch__.settings.to_hash)
          mappings.deep_merge!(klass.__elasticsearch__.mappings.to_hash)
        end

        proxy = Project.__elasticsearch__.version(version)
        client = proxy.client
        index_name = proxy.index_name

        # ES5.6 needs a setting enabled to support JOIN datatypes that ES6 does not support...
        if Gitlab::VersionInfo.parse(client.info['version']['number']) < Gitlab::VersionInfo.new(6)
          settings['index.mapping.single_type'] = true
        end

        if client.indices.exists? index: index_name
          client.indices.delete index: index_name
        end

        client.indices.create index: index_name,
                              body: {
                                settings: settings.to_hash,
                                mappings: mappings.to_hash
                              }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def self.delete_index(version = ::Elastic::MultiVersionUtil::TARGET_VERSION)
        Project.__elasticsearch__.version(version).delete_index!
      end

      # Calls Elasticsearch refresh API to ensure data is searchable
      # immediately.
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-refresh.html
      def self.refresh_index
        Project.__elasticsearch__.refresh_index!
      end

      def self.index_size(version = ::Elastic::MultiVersionUtil::TARGET_VERSION)
        Project.__elasticsearch__.version(version).client.indices.stats['indices'][Project.__elasticsearch__.index_name]['total']
      end
    end
  end
end
