# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Packages::PackageFile, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }
  end

  it_behaves_like 'UpdateProjectStatistics' do
    subject { build(:package_file, :jar, size: 42) }
  end
end
