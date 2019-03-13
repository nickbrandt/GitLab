# frozen_string_literal: true

require 'rails_helper'

describe DesignManagement::Design do
  describe 'relations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:issue) }
    it { is_expected.to have_many(:versions) }
  end

  describe 'validations' do
    subject(:design) { build(:design) }

    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:issue) }
    it { is_expected.to validate_presence_of(:filename) }
    it { is_expected.to validate_uniqueness_of(:issue) }
    it { is_expected.to validate_uniqueness_of(:filename).scoped_to(:issue_id) }
  end
end
