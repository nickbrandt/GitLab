# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::Fdw::LfsObjectsProject, :geo, type: :model do
  context 'relationships' do
    it { is_expected.to belong_to(:lfs_object).class_name('Geo::Fdw::LfsObject').inverse_of(:projects) }
    it { is_expected.to belong_to(:project).class_name('Geo::Fdw::Project').inverse_of(:lfs_objects) }
  end
end
