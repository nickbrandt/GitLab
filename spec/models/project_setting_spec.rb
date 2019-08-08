# frozen_string_literal: true

require 'spec_helper'

describe ProjectSetting do
  describe 'relations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:forking_enabled).in_array([true, false]) }
  end
end
