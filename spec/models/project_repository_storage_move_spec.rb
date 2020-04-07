# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectRepositoryStorageMove, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:state) }
    it { is_expected.to validate_presence_of(:source_storage_name) }
    it { is_expected.to validate_presence_of(:destination_storage_name) }

    context 'source_storage_name inclusion' do
      subject { build(:project_repository_storage_move, source_storage_name: 'missing') }

      it "does not allow repository storages that don't match a label in the configuration" do
        expect(subject).not_to be_valid
        expect(subject.errors[:source_storage_name].first).to match(/is not included in the list/)
      end
    end

    context 'destination_storage_name inclusion' do
      subject { build(:project_repository_storage_move, destination_storage_name: 'missing') }

      it "does not allow repository storages that don't match a label in the configuration" do
        expect(subject).not_to be_valid
        expect(subject.errors[:destination_storage_name].first).to match(/is not included in the list/)
      end
    end
  end
end
