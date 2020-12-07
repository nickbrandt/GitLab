# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class CreateSecuritySetting
      def perform(project_ids)
      end
    end
  end
end

Gitlab::BackgroundMigration::CreateSecuritySetting.prepend_if_ee('EE::Gitlab::BackgroundMigration::CreateSecuritySetting')
