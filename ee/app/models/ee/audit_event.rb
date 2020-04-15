# frozen_string_literal: true

module EE
  module AuditEvent
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      scope :by_entity, -> (entity_type, entity_id) { by_entity_type(entity_type).by_entity_id(entity_id) }
    end

    def entity
      lazy_entity
    end

    def present
      AuditEventPresenter.new(self)
    end

    def lazy_entity
      BatchLoader.for(entity_id)
        .batch(
          key: entity_type, default_value: ::Gitlab::Audit::NullEntity.new
        ) do |ids, loader, args|
          model = Object.const_get(args[:key], false)
          model.where(id: ids).find_each { |record| loader.call(record.id, record) }
        end
    end
  end
end
