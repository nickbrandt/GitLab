# frozen_string_literal: true
require 'rails_helper'

describe DesignManagement::Version do
  describe 'relations' do
    it { is_expected.to have_and_belong_to_many(:designs) }

    it 'constrains the designs relation correctly' do
      design = create(:design)
      version = create(:design_version)

      version.designs << design

      expect { version.designs << design }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows adding multiple versions to a single design' do
      design = create(:design)
      versions = create_list(:design_version, 2)

      expect { versions.each { |v| design.versions << v } }
        .not_to raise_error
    end

    it { is_expected.to have_many(:notes).dependent(:delete_all) }
  end

  describe 'validations' do
    subject(:design_version) { build(:design_version) }

    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:sha) }
    it { is_expected.to validate_uniqueness_of(:sha).case_insensitive }
  end
end
