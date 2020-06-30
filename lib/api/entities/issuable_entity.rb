# frozen_string_literal: true

module API
  module Entities
    class IssuableEntity < Grape::Entity
      expose :id, :iid
      expose(:project_id) { |entity| entity&.project.try(:id) }
      expose :title, :description
      expose :state, :created_at, :updated_at

      def presented
        lazy_issuable_metadata

        super
      end

      def issuable_metadata
        lazy_issuable_metadata
      end

      protected

      def lazy_issuable_metadata
        BatchLoader.for(object).batch(key: :issuable_metadata) do |models, loader|
          issuable_metadata = Gitlab::IssuableMetadata.new(nil, models)
          metadata_by_id = issuable_metadata.data

          models.each do |issuable|
            loader.call(issuable, metadata_by_id[issuable.id])
          end
        end
      end
    end
  end
end
