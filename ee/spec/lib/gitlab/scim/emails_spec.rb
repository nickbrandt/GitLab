# frozen_string_literal: true

require 'spec_helper'

describe ::EE::Gitlab::Scim::Emails do
  let(:user) { create(:user) }
  let(:identity) { create(:group_saml_identity, user: user) }

  let(:entity) do
    described_class.new(user)
  end

  subject { entity.as_json }

  it 'contains the email' do
    expect(subject[:value]).to eq(user.email)
  end

  it 'contains the type' do
    expect(subject[:type]).to eq('work')
  end

  it 'contains the email' do
    expect(subject[:primary]).to be true
  end
end
