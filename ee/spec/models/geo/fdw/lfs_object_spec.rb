# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::Fdw::LfsObject, :geo, type: :model do
  context 'relationships' do
    it { is_expected.to have_many(:lfs_objects_projects).class_name('Geo::Fdw::LfsObjectsProject') }
    it { is_expected.to have_many(:projects).class_name('Geo::Fdw::Project').through(:lfs_objects_projects) }
  end
end
