# frozen_string_literal: true

require 'spec_helper'

describe ::EE::Gitlab::Scim::User do
  let(:user) { create(:user) }
  let(:identity) { create(:group_saml_identity, user: user) }

  let(:entity) do
    described_class.new(identity)
  end

  subject { entity.as_json }

  it 'contains the schemas' do
    expect(subject[:schemas]).to eq(["urn:ietf:params:scim:schemas:core:2.0:User"])
  end

  it 'contains the extern UID' do
    expect(subject[:id]).to eq(identity.extern_uid)
  end

  it 'contains the active flag' do
    expect(subject[:active]).to be true
  end

  it 'contains the name' do
    expect(subject[:'name.formatted']).to eq(user.name)
  end

  it 'contains the email' do
    expect(subject[:emails].first[:value]).to eq(user.email)
  end
end
