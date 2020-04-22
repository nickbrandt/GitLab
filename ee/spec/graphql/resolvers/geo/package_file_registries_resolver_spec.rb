# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::Geo::PackageFileRegistriesResolver do
  it_behaves_like 'a Geo registries resolver', :package_file_registry
end
