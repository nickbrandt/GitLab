# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      class BatchModelLoader
        attr_reader :model_class, :model_id, :scopes

        # Scopes may be passed - any scopes should only be used for pre-loading
        # associations.
        def initialize(model_class, model_id, *scopes)
          @model_class, @model_id, @scopes = model_class, model_id.to_i, scopes
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def find
          BatchLoader::GraphQL.for(self).batch do |loader_info, loader|
            per_model = loader_info.group_by(&:model_class)
            per_model.each do |model, info|
              ids = info.map(&:model_id)
              scopes = info.flat_map(&:scopes).uniq
              results = scopes.reduce(model.where(id: ids)) { |r, scope| r.public_send(scope) }

              results.each do |record|
                key = self.class.new(model, record.id)
                loader.call(key, record)
              end
            end
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def eql?(other)
          return false unless other.class == self.class
          
          model_class == other.model_class && model_id == other.model_id
        end

        def hash
          [model_class, model_id].hash
        end
      end
    end
  end
end
