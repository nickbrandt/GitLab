# frozen_string_literal: true

class Geo::UploadRegistry < Geo::FileRegistry
  belongs_to :upload, foreign_key: :file_id

  if Rails.gem_version >= Gem::Version.new('6.0')
    raise '.type_condition was changed in Rails 6.0, please adapt this code accordingly'
    # see https://github.com/rails/rails/commit/6a1a1e66ea7a917942bd8369fa8dbfedce391dab
  end

  def self.type_condition(table = arel_table)
    sti_column = arel_attribute(inheritance_column, table)
    sti_names  = Geo::FileService::DEFAULT_OBJECT_TYPES

    sti_column.in(sti_names)
  end

  def self.with_search(query)
    return all if query.nil?

    where(file_id: Geo::Fdw::Upload.search(query))
  end

  def file
    upload&.path || s_('Removed %{type} with id %{id}') % { type: file_type, id: file_id }
  end

  def project
    return upload.model if upload&.model.is_a?(Project)
  end
end
