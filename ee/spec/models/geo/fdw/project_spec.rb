# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::Fdw::Project, :geo_fdw, type: :model do
  context 'relationships' do
    it { is_expected.to have_many(:container_repositories).class_name('Geo::Fdw::ContainerRepository') }
  end
end
