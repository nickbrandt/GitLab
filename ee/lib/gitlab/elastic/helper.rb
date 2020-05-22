# frozen_string_literal: true

module Gitlab
  module Elastic
    class Helper
      attr_reader :version, :client
      attr_accessor :target_name

      def initialize(
        version: ::Elastic::MultiVersionUtil::TARGET_VERSION,
        client: nil,
        target_name: nil)

        proxy = self.class.create_proxy(version)

        @client = client || proxy.client
        @target_name = target_name || proxy.index_name
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

      def create_empty_index(with_alias: true)
        if index_exists?
          raise "Index under '#{target_name}' already exists, use `recreate_index` to recreate it."
        end

        settings = {}
        mappings = {}

        new_index_name = with_alias ? "#{target_name}-#{Time.now.strftime("%Y%m%d-%H%M")}" : target_name

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
          index: new_index_name,
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

        client.indices.create create_index_options
        client.indices.put_alias(name: target_name, index: new_index_name) if with_alias
      end

      def delete_index
        result = client.indices.delete(index: target_index_name)
        result['acknowledged']
      rescue ::Elasticsearch::Transport::Transport::Errors::NotFound => e
        Gitlab::ErrorTracking.log_exception(e)
        false
      end

      def index_exists?
        client.indices.exists?(index: target_name) # rubocop:disable CodeReuse/ActiveRecord
      end

      def alias_exists?
        client.indices.exists_alias(name: target_name)
      end

      # Calls Elasticsearch refresh API to ensure data is searchable
      # immediately.
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-refresh.html
      def refresh_index
        client.indices.refresh(index: target_name)
      end

      def index_size
        client.indices.stats['indices'][target_index_name]['total']
      end

      private

      # This method is used when we need to get an actual index name (if it's used through an alias)
      def target_index_name
        if alias_exists?
          client.indices.get_alias(name: target_name).each_key.first
        else
          target_name
        end
      end
    end
  end
end
