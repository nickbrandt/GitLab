# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Auth::GroupSaml::SsoState do
  let(:saml_provider_id) { 10 }

  subject { described_class.new(saml_provider_id) }

  describe '#update_active' do
    it 'updates the current sign in state' do
      Gitlab::Session.with_session({}) do
        new_state = double
        subject.update_active(new_state)

        expect(Gitlab::Session.current[:active_group_sso_sign_ins]).to eq({ saml_provider_id => new_state })
      end
    end
  end

  describe '#active?' do
    it 'gets the current sign in state' do
      current_state = double

      Gitlab::Session.with_session(active_group_sso_sign_ins: { saml_provider_id => current_state }) do
        expect(subject.active?).to eq current_state
      end
    end
  end
end
