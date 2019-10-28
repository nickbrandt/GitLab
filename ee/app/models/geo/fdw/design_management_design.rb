# frozen_string_literal: true

module Geo
  module Fdw
    class DesignManagementDesign < ::Geo::BaseFdw
      self.table_name = Gitlab::Geo::Fdw.foreign_table_name('design_management_designs')
      self.primary_key = :id
    end
  end
end
