# frozen_string_literal: true

class Geo::UploadRegistry < Geo::FileRegistry
  belongs_to :upload, foreign_key: :file_id

  def self.type_condition(table = arel_table)
    sti_column = arel_attribute(inheritance_column, table)
    sti_names  = Geo::FileService::DEFAULT_OBJECT_TYPES

    sti_column.in(sti_names)
  end
end
