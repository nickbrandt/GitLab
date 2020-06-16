# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::PackageFileReplicator do
  let(:model_record) { build(:package_file, :npm) }

  include_examples 'a blob replicator'

  include_examples 'secondary counters', :geo_package_file_registry
end
