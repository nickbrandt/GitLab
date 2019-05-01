# frozen_string_literal: true

module DesignManagement
  class DesignVersion < ApplicationRecord
    self.table_name = "#{DesignManagement.table_name_prefix}designs_versions"

    belongs_to :design, class_name: "DesignManagement::Design", inverse_of: :design_versions
    belongs_to :version, class_name: "DesignManagement::Version", inverse_of: :design_versions
  end
end
