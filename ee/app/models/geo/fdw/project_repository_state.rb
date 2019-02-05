# frozen_string_literal: true

module Geo
  module Fdw
    class ProjectRepositoryState < ::Geo::BaseFdw
      self.table_name = Gitlab::Geo::Fdw.foreign_table_name('project_repository_states')
    end
  end
end
