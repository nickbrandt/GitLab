# frozen_string_literal: true

require 'spec_helper'

describe Autocomplete::UsersFinder do
  it 'returns only users with that SAML provider when saml_provider_id is given' do
    current_user = create(:user)
    user1 = create(:user, username: 'samdoe')
    user2 = create(:user, username: 'allymolly')
    group = create(:group)
    saml_provider = create(:saml_provider, group: group)
    create(:identity, saml_provider: saml_provider, user: user1)
    params = { saml_provider_id: saml_provider.id }
    group.add_users([user1, user2], GroupMember::DEVELOPER)

    users = described_class.new(params: params, current_user: current_user, project: nil, group: nil).execute.to_a

    expect(users).to match_array([user1])
  end
end
