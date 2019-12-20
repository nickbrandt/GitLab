# frozen_string_literal: true

require 'spec_helper'

describe API::Helpers::PackagesManagerClientsHelpers do
  let_it_be(:personal_access_token) { create(:personal_access_token) }
  let_it_be(:username) { personal_access_token.user.username }
  let(:password) { personal_access_token.token }

  describe '#find_personal_access_token_from_http_basic_auth' do
    let(:headers) { { Authorization: basic_http_auth(username, password) } }
    let(:helper) { Class.new.include(described_class).new }

    subject { helper.find_personal_access_token_from_http_basic_auth }

    before do
      allow(helper).to receive(:headers).and_return(headers&.with_indifferent_access)
    end

    context 'with a valid Authorization header' do
      it { is_expected.to eq personal_access_token }
    end

    context 'with an invalid Authorization header' do
      where(:headers) do
        [
          [{ Authorization: 'Invalid' }],
          [{}],
          [nil]
        ]
      end

      with_them do
        it { is_expected.to be nil }
      end
    end

    context 'with an unknown Authorization header' do
      let(:password) { 'Unknown' }

      it { is_expected.to be nil }
    end
  end

  def basic_http_auth(username, password)
    ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
  end
end
