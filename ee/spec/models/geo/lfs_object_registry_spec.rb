# frozen_string_literal: true

require 'spec_helper'

describe Geo::LfsObjectRegistry, :geo do
  describe 'relationships' do
    it { is_expected.to belong_to(:lfs_object).class_name('LfsObject') }
  end
end
