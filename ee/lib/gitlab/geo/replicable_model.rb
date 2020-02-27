# frozen_string_literal: true

module Gitlab
  module Geo
    module ReplicableModel
      extend ActiveSupport::Concern

      included do
        # If this hook turns out not to apply to all Models, perhaps we should extract a `ReplicableBlobModel`
        after_create_commit -> { replicator.handle_after_create_commit if replicator.respond_to?(:handle_after_create_commit) }
      end

      class_methods do
        def with_replicator(klass)
          raise ArgumentError, 'Must be a class inheriting from Gitlab::Geo::Replicator' unless klass < ::Gitlab::Geo::Replicator

          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            define_method :replicator do
              @_replicator ||= klass.new(model_record: self)
            end
          RUBY
        end
      end

      # Geo Replicator
      #
      # @return [Gitlab::Geo::Replicator]
      def replicator
        raise NotImplementedError, 'There is no Replicator defined for this model'
      end
    end
  end
end
