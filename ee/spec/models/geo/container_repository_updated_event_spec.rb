# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ContainerRepositoryUpdatedEvent, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:container_repository).class_name('ContainerRepository') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:container_repository) }
  end
end
