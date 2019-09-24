# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::Fdw::LfsObject, :geo, type: :model do
  context 'relationships' do
    it { is_expected.to have_many(:lfs_objects_projects).class_name('Geo::Fdw::LfsObjectsProject') }
    it { is_expected.to have_many(:projects).class_name('Geo::Fdw::Project').through(:lfs_objects_projects) }
  end

  describe '.missing_file_registry', :geo_fdw do
    subject { described_class.missing_file_registry }

    it 'returns lfs objects that doesnt have a corresponding file registry entry' do
      lfs_objects = create_list(:lfs_object, 2)

      # simulate existing registry entries with the same +id+, but different +file_type+
      lfs_objects.each do |lfs|
        create(:geo_file_registry, file_id: lfs.id)
      end

      expect(subject).to match_ids(lfs_objects)
    end
  end
end
