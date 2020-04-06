# frozen_string_literal: true

module Gitlab
  module Elastic
    class Helper
      # rubocop: disable CodeReuse/ActiveRecord
      def self.create_empty_index(version = ::Elastic::MultiVersionUtil::TARGET_VERSION, client = nil)
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
        client ||= proxy.client
        index_name = proxy.index_name

        create_index_options = {
          index: index_name,
          body: {
            settings: settings.to_hash,
            mappings: mappings.to_hash
          }
        }

        # include_type_name defaults to false in ES7. This will ensure ES7
        # behaves like ES6 when creating mappings. See
        # https://www.elastic.co/blog/moving-from-types-to-typeless-apis-in-elasticsearch-7-0
        # for more information. We also can't set this for any versions before
        # 6.8 as this parameter was not supported. Since it defaults to true in
        # all 6.x it's safe to only set it for 7.x.
        if Gitlab::VersionInfo.parse(client.info['version']['number']).major == 7
          create_index_options[:include_type_name] = true
        end

        if client.indices.exists? index: index_name
          client.indices.delete index: index_name
        end

        client.indices.create create_index_options
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def self.reindex_to_another_cluster(source_cluster_url, destination_cluster_url, version = ::Elastic::MultiVersionUtil::TARGET_VERSION)
        proxy = Project.__elasticsearch__.version(version)
        index_name = proxy.index_name

        destination_client = Gitlab::Elastic::Client.build(url: destination_cluster_url)

        create_empty_index(version, destination_client)

        optimize_for_write_settings = { index: { number_of_replicas: 0, refresh_interval: "-1" } }
        destination_client.indices.put_settings(index: index_name, body: optimize_for_write_settings)

        source_addressable = Addressable::URI.parse(source_cluster_url)

        response = destination_client.reindex(body: {
          source: {
            remote: {
              host: source_addressable.omit(:user, :password).to_s,
              username: source_addressable.user,
              password: source_addressable.password
            },
            index: index_name
          },
          dest: {
            index: index_name
          }
        }, wait_for_completion: false)

        response['task']
      end

      def self.delete_index(version = ::Elastic::MultiVersionUtil::TARGET_VERSION)
        Project.__elasticsearch__.version(version).delete_index!
      end

      def self.index_exists?(version = ::Elastic::MultiVersionUtil::TARGET_VERSION)
        proxy = Project.__elasticsearch__.version(version)
        client = proxy.client
        index_name = proxy.index_name

        client.indices.exists? index: index_name # rubocop:disable CodeReuse/ActiveRecord
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
