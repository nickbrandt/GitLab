# frozen_string_literal: true

module Geo
  module Fdw
    class ProjectFeature < ::Geo::BaseFdw
      self.table_name = Gitlab::Geo::Fdw.foreign_table_name('project_features')
    end
  end
end
