# frozen_string_literal: true
require 'spec_helper'

describe Groups::SamlProvidersController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:user) { create(:user) }

  render_views

  before_all do
    clean_frontend_fixtures('groups/saml_providers/')

    group.add_owner(user)
  end

  before do
    allow(Devise).to receive(:omniauth_providers).and_return(%i(group_saml))
    stub_licensed_features(group_saml: true)

    sign_in(user)
  end

  it 'groups/saml_providers/show.html' do
    create(:saml_provider, group: group)

    get :show, params: { group_id: group }

    expect(response).to be_successful
    expect(response).to render_template 'groups/saml_providers/show'
  end
end
