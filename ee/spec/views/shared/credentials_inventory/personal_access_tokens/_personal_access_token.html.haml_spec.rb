# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('shared/credentials_inventory/personal_access_tokens/_personal_access_token.html.haml') do
  let(:user) { create(:user) }
  let(:expiry_date) { 20.days.since }
  let(:personal_access_token) { create(:personal_access_token, user: user, expires_at: expiry_date)}

  before do
    allow(view).to receive(:user_detail_path).and_return('abcd')
    render 'shared/credentials_inventory/personal_access_tokens/personal_access_token', personal_access_token: personal_access_token
  end

  it 'shows the users name' do
    expect(rendered).to have_text(user.name)
  end

  it 'shows the created on date' do
    expect(rendered).to have_text(personal_access_token.created_at.to_date.to_s)
  end

  it 'shows the expiry date' do
    expect(rendered).to have_text(personal_access_token.expires_at.to_date.to_s)
  end

  context 'revoked date' do
    let(:updated_at_date) { 10.days.ago }

    context 'when set' do
      let(:personal_access_token) { create(:personal_access_token, user: user, updated_at: updated_at_date, revoked: true)}

      before do
        render 'shared/credentials_inventory/personal_access_tokens/personal_access_token', personal_access_token: personal_access_token
      end

      it 'shows the last accessed on date' do
        expect(rendered).to have_text(personal_access_token.updated_at.to_date.to_s)
      end
    end

    context 'when not set' do
      let(:personal_access_token) { create(:personal_access_token, user: user, updated_at: updated_at_date)}

      before do
        render 'shared/credentials_inventory/personal_access_tokens/personal_access_token', personal_access_token: personal_access_token
      end

      it 'shows "Never" for the last accessed on date' do
        expect(rendered).not_to have_text(updated_at_date.to_date.to_s)
      end
    end
  end
  context 'scopes' do
    context 'when set' do
      let(:scopes) { %w(api read_user read_api) }
      let(:personal_access_token) { create(:personal_access_token, user: user, scopes: scopes)}

      before do
        render 'shared/credentials_inventory/personal_access_tokens/personal_access_token', personal_access_token: personal_access_token
      end

      it 'shows the scopes' do
        expect(rendered).to have_text(personal_access_token.scopes.join(', '))
      end
    end

    context 'when not set' do
      let(:personal_access_token) { create(:personal_access_token, user: user)}

      before do
        # Turns out on creation of a PersonalAccessToken we set some default scopes and you can't pass `nil`
        # This is forcing the scope to be `nil` even though it looks impossible to do, we have the logic in the view
        personal_access_token.scopes = nil

        render 'shared/credentials_inventory/personal_access_tokens/personal_access_token', personal_access_token: personal_access_token
      end

      it 'shows "No Scopes"' do
        expect(rendered).to have_text('Scope No Scopes')
      end
    end
  end
end
