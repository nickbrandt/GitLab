# frozen_string_literal: true

require 'spec_helper'

describe Geo::PackageFileRegistry, :geo, type: :model do
  let_it_be(:registry) { create(:package_file_registry) }

  specify 'factory is valid' do
    expect(registry).to be_valid
  end
end
