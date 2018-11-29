# frozen_string_literal: true
#
require 'spec_helper'

describe EE::AuthHelper do
  describe "form_based_providers" do
    context 'with smartcard_auth feature flag off' do
      before do
        stub_licensed_features(smartcard_auth: false)
        allow(helper).to receive(:smartcard_enabled?).and_call_original
      end

      it 'does not include smartcard provider' do
        allow(helper).to receive(:auth_providers) { [:twitter, :smartcard] }
        expect(helper.form_based_providers).to be_empty
      end
    end

    context 'with smartcard_auth feature flag on' do
      before do
        stub_licensed_features(smartcard_auth: true)
        allow(helper).to receive(:smartcard_enabled?).and_return(true)
      end

      it 'includes smartcard provider' do
        allow(helper).to receive(:auth_providers) { [:twitter, :smartcard] }
        expect(helper.form_based_providers).to eq %i(smartcard)
      end
    end
  end
end
