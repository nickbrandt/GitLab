require 'spec_helper'

RSpec.describe Geo::UploadDeletedEvent, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:upload) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:upload) }
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_presence_of(:checksum) }
    it { is_expected.to validate_presence_of(:model_id) }
    it { is_expected.to validate_presence_of(:model_type) }
  end
end
