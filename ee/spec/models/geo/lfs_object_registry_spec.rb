# frozen_string_literal: true

require 'spec_helper'

describe Geo::LfsObjectRegistry, :geo do
  set(:lfs_registry) { create(:geo_file_registry, :lfs, :with_file) }
  set(:attachment_registry) { create(:geo_file_registry, :attachment) }

  it 'only finds lfs registries' do
    expect(described_class.all).to match_ids(lfs_registry)
  end

  it 'finds associated LfsObject record' do
    expect(described_class.find(lfs_registry.id).lfs_object).to be_an_instance_of(LfsObject)
  end
end
