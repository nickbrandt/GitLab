# frozen_string_literal: true

module Gitlab
  module Elastic
    class Helper
      attr_reader :version, :client
      attr_accessor :index_name

      def initialize(
        version: ::Elastic::MultiVersionUtil::TARGET_VERSION,
        client: nil,
        index_name: nil)

        proxy = self.class.create_proxy(version)

        @client = client || proxy.client
        @index_name = index_name || proxy.index_name
        @version = version
      end

      class << self
        def create_proxy(version = nil)
          Project.__elasticsearch__.version(version)
        end

        def default
          @default ||= self.new
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def create_empty_index
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

        if client.indices.exists?(index: index_name)
          raise "Index '#{index_name}' already exists, use `recreate_index` to recreate it."
        end

        client.indices.create create_index_options
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def delete_index
        result = client.indices.delete(index: index_name)
        result['acknowledged']
      rescue ::Elasticsearch::Transport::Transport::Errors::NotFound => e
        Gitlab::ErrorTracking.log_exception(e)
        false
      end

      def index_exists?
        client.indices.exists?(index: index_name) # rubocop:disable CodeReuse/ActiveRecord
      end

      # Calls Elasticsearch refresh API to ensure data is searchable
      # immediately.
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-refresh.html
      def refresh_index
        client.indices.refresh(index: index_name)
      end

      def index_size
        client.indices.stats['indices'][index_name]['total']
      end
    end
  end
end
