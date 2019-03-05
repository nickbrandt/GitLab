# frozen_string_literal: true
require 'rails_helper'

describe DesignManagement::Version do
  describe 'relations' do
    it { is_expected.to belong_to(:design) }
    it { is_expected.to have_one(:issue) }
    it { is_expected.to have_one(:project) }
    it { is_expected.to have_many(:notes).dependent(:delete_all) }
  end

  describe 'validations' do
    subject(:design_version) { build(:design_version) }

    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:design) }
    it { is_expected.to validate_presence_of(:sha) }
    it { is_expected.to validate_uniqueness_of(:sha).case_insensitive }
  end
end
