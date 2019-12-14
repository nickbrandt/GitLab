# frozen_string_literal: true

module Geo
  module Fdw
    class LfsObjectsProject < ::Geo::BaseFdw
      self.table_name = Gitlab::Geo::Fdw.foreign_table_name('lfs_objects_projects')

      belongs_to :lfs_object, class_name: 'Geo::Fdw::LfsObject', inverse_of: :projects
      belongs_to :project, class_name: 'Geo::Fdw::Project', inverse_of: :lfs_objects

      scope :project_id_in, ->(ids) { where(project_id: ids) }
    end
  end
end
