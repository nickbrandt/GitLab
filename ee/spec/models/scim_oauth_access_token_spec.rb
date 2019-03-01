require 'spec_helper'

describe ScimOauthAccessToken do
  describe "Associations" do
    it { is_expected.to belong_to :group }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:group) }
  end

  describe '#token' do
    it 'generates a token on creation' do
      scim_token = described_class.create(group: create(:group))

      expect(scim_token.token).to be_a(String)
    end
  end
end
