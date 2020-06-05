# frozen_string_literal: true

RSpec.shared_examples 'exposes required fields for import entity' do
  describe 'exposes required fields' do
    it 'exposes id' do
      expect(subject).to include(:id)
    end

    it 'exposes full name' do
      expect(subject).to include(:full_name)
    end

    it 'exposes owner name' do
      expect(subject).to include(:owner_name)
    end

    it 'exposes sanitized name' do
      expect(subject).to include(:sanitized_name)
    end

    it 'exposes provider link' do
      expect(subject).to include(:provider_link)
    end
  end
end
