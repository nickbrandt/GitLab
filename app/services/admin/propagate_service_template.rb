# frozen_string_literal: true

module Admin
  class PropagateServiceTemplate
    BATCH_SIZE = 100

    delegate :data_fields_present?, to: :integration

    def self.propagate(integration)
      new(integration).propagate
    end

    def initialize(integration)
      @integration = integration
    end

    def propagate
      return unless integration.active?

      propagate_projects_with_template
    end

    private

    attr_reader :integration

    def propagate_projects_with_template
      loop do
        batch_ids = Project.uncached { Project.ids_without_integration(integration, BATCH_SIZE) }

        bulk_create_from_template(batch_ids) unless batch_ids.empty?

        break if batch_ids.size < BATCH_SIZE
      end
    end

    def bulk_create_from_template(batch_ids)
      service_list = ServiceList.new(batch_ids, service_hash).to_array

      Service.transaction do
        results = bulk_insert(*service_list)

        if data_fields_present?
          data_list = DataList.new(results, data_fields_hash, integration.data_fields.class).to_array

          bulk_insert(*data_list)
        end

        run_callbacks(batch_ids)
      end
    end

    def bulk_insert(klass, columns, values_array)
      items_to_insert = values_array.map { |array| Hash[columns.zip(array)] }

      klass.insert_all(items_to_insert, returning: [:id])
    end

    def service_hash
      @service_hash ||= integration.to_service_hash
    end

    def data_fields_hash
      @data_fields_hash ||= integration.to_data_fields_hash
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def run_callbacks(batch_ids)
      if integration.issue_tracker?
        Project.where(id: batch_ids).update_all(has_external_issue_tracker: true)
      end

      if active_external_wiki?
        Project.where(id: batch_ids).update_all(has_external_wiki: true)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def active_external_wiki?
      integration.type == 'ExternalWikiService'
    end
  end
end
