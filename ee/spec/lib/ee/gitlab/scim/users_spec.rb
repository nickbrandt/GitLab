# frozen_string_literal: true

require 'spec_helper'

describe ::EE::Gitlab::Scim::Users do
  let(:user) { build(:user) }
  let(:identity) { build(:group_saml_identity, user: user) }

  let(:entity) do
    described_class.new(identity)
  end

  subject { entity.as_json }

  it 'contains the schemas' do
    expect(subject[:schemas]).to eq(['urn:ietf:params:scim:api:messages:2.0:ListResponse'])
  end

  it 'contains the totalResults' do
    expect(subject[:totalResults]).to eq(1)
  end

  it 'contains the itemsPerPage' do
    expect(subject[:itemsPerPage]).to eq(20)
  end

  it 'contains the startIndex' do
    expect(subject[:startIndex]).to eq(1)
  end

  it 'contains the user' do
    expect(subject[:Resources]).not_to be_empty
  end

  it 'contains the user ID' do
    expect(subject[:Resources].first[:id]).to eq(identity.extern_uid)
  end
end
