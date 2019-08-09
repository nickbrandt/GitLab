# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::Fdw::ContainerRepository, :geo, type: :model do
  context 'relationships' do
    it { is_expected.to belong_to(:project).class_name('Geo::Fdw::Project') }
  end
end
