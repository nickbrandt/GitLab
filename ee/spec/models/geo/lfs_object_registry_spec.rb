# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::LfsObjectRegistry, :geo do
  describe 'relationships' do
    it { is_expected.to belong_to(:lfs_object).class_name('LfsObject') }
  end

  it_behaves_like 'a BulkInsertSafe model', Geo::LfsObjectRegistry do
    let(:valid_items_for_bulk_insertion) { build_list(:geo_lfs_object_registry, 10) }
    let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
  end
end
