# frozen_string_literal: true
require 'rails_helper'

RSpec.describe DependencyProxy::Blob, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:file) }
    it { is_expected.to validate_presence_of(:file_name) }
  end

  describe '.total_size' do
    it 'returns 0 if no files' do
      expect(described_class.total_size).to eq(0)
    end

    it 'returns a correct sum of all files sizes' do
      create(:dependency_proxy_blob, size: 10)
      create(:dependency_proxy_blob, size: 20)

      expect(described_class.total_size).to eq(30)
    end
  end

  describe '.find_or_build' do
    let!(:blob) { create(:dependency_proxy_blob) }

    it 'builds new instance if not found' do
      expect(described_class.find_or_build('foo.gz')).not_to be_persisted
    end

    it 'finds an existing blob' do
      expect(described_class.find_or_build(blob.file_name)).to eq(blob)
    end
  end
end
