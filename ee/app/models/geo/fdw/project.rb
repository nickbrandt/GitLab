# frozen_string_literal: true

module Geo
  module Fdw
    class Project < ::Geo::BaseFdw
      include Routable

      self.primary_key = :id
      self.table_name = Gitlab::Geo::Fdw.foreign_table_name('projects')

      belongs_to :namespace, class_name: 'Geo::Fdw::Namespace'

      alias_method :parent, :namespace

      class << self
        def within_namespaces(namespace_ids)
          where(arel_table.name => { namespace_id: namespace_ids })
        end

        def within_shards(shard_names)
          where(repository_storage: Array(shard_names))
        end
      end
    end
  end
end
