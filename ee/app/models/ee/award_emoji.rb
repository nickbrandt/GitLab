# frozen_string_literal: true

module EE
  module AwardEmoji
    extend ActiveSupport::Concern

    prepended do
      UPDATE_ELASTIC_ASSOCIATIONS_FOR = [::Issue].freeze

      after_commit :update_elastic_associations, on: [:create, :destroy]

      def update_elastic_associations
        return unless awardable
        return unless UPDATE_ELASTIC_ASSOCIATIONS_FOR.include?(awardable_type&.constantize)

        awardable.maintain_elasticsearch_update if awardable.maintaining_elasticsearch?
      end
    end
  end
end
