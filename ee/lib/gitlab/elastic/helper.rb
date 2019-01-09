# frozen_string_literal: true

module Gitlab
  module Elastic
    class Helper
      # rubocop: disable CodeReuse/ActiveRecord
      def self.create_empty_index
        index_name = Project.index_name
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
          settings.deep_merge!(klass.settings.to_hash)
          mappings.deep_merge!(klass.mappings.to_hash)
        end

        client = Project.__elasticsearch__.client

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

      def self.delete_index
        Project.__elasticsearch__.delete_index!
      end

      def self.refresh_index
        Project.__elasticsearch__.refresh_index!
      end

      def self.index_size
        Project.__elasticsearch__.client.indices.stats['indices'][Project.__elasticsearch__.index_name]['total']
      end
    end
  end
end
