# frozen_string_literal: true

class MigrateServicesToHttpIntegrations < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  ALERT_SERVICE_TYPE = 'AlertsService'
  SERVICE_NAMES_IDENTIFIER = {
    name: 'HTTP endpoint',
    identifier: 'legacy'
  }

  class HttpIntegration < ActiveRecord::Base
    self.table_name = 'alert_management_http_integrations'
  end

  # For each Alerts service,
  # Create the matching HttpIntegration
  def up
    HttpIntegration.reset_column_information

    sql = <<~SQL
      SELECT * FROM services
      JOIN alerts_service_data
      ON (services.id = alerts_service_data.service_id)
      WHERE type = '#{ALERT_SERVICE_TYPE}'
    SQL

    select_all(sql).each do |alerts_service|
      HttpIntegration.create!(
        project_id: alerts_service['project_id'],
        name: SERVICE_NAMES_IDENTIFIER[:name],
        endpoint_identifier: SERVICE_NAMES_IDENTIFIER[:identifier],
        encrypted_token: alerts_service['encrypted_token'],
        encrypted_token_iv: alerts_service['encrypted_token_iv'],
        active: alerts_service['active']
      )
    end
  end

  def down
    sql = <<~SQL
      SELECT project_id FROM services
      WHERE type = '#{ALERT_SERVICE_TYPE}'
    SQL

    select_values(sql).each do |project_id|
      HttpIntegration
        .where(project_id: project_id, endpoint_identifier: SERVICE_NAMES_IDENTIFIER[:identifier])
        .delete_all
    end
  end
end
