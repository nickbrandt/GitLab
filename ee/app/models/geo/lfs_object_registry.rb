# frozen_string_literal: true

class Geo::LfsObjectRegistry < Geo::FileRegistry
  belongs_to :lfs_object, foreign_key: :file_id, class_name: 'LfsObject'

  def self.sti_name
    'lfs'
  end
end
