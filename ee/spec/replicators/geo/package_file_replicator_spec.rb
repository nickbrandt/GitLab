# frozen_string_literal: true

require 'spec_helper'

describe Geo::PackageFileReplicator do
  let(:model_record) { build(:package_file, :npm) }

  it_behaves_like 'a blob replicator'
end
