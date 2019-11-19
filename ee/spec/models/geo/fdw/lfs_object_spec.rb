# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::Fdw::LfsObject, :geo, type: :model do
  context 'relationships' do
    it { is_expected.to have_many(:lfs_objects_projects).class_name('Geo::Fdw::LfsObjectsProject') }
    it { is_expected.to have_many(:projects).class_name('Geo::Fdw::Project').through(:lfs_objects_projects) }
  end

  describe '.missing_registry', :geo_fdw do
    it "returns lfs objects that don't have a corresponding registry entry" do
      missing_registry_entries = create_list(:lfs_object, 2)

      create_list(:lfs_object, 2).each do |lfs|
        create(:geo_lfs_object_registry, lfs_object_id: lfs.id)
      end

      expect(described_class.missing_registry).to match_ids(missing_registry_entries)
    end
  end
end
