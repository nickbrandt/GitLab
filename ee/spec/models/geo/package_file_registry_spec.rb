# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::PackageFileRegistry, :geo, type: :model do
  it_behaves_like 'a BulkInsertSafe model', Geo::PackageFileRegistry do
    let(:valid_items_for_bulk_insertion) { build_list(:package_file_registry, 10, created_at: Time.zone.now) }
    let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
  end

  include_examples 'a Geo framework registry'
end
