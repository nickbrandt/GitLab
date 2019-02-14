# frozen_string_literal: true

require 'spec_helper'

describe SessionsController do
  include DeviseHelpers
  include EE::GeoHelpers

  describe '#new' do
    before do
      set_devise_mapping(context: @request)
    end

    context 'on a Geo secondary node' do
      set(:primary_node) { create(:geo_node, :primary) }
      set(:secondary_node) { create(:geo_node) }

      let(:salt) { 'MTAwZDhjYmQxNzUw' }
      let(:login_state) { Gitlab::Geo::Oauth::LoginState.new(salt: salt, return_to: '/') }

      before do
        stub_current_geo_node(secondary_node)
        allow(SecureRandom).to receive(:hex).and_return(salt)
      end

      context 'with a tampered HOST header' do
        it 'prevents open redirect attack' do
          request.headers['HOST'] = 'http://this.is.not.my.host'

          get(:new)

          expect(response).to have_gitlab_http_status(302)
          expect(response).to redirect_to(oauth_geo_auth_url(host: secondary_node.url, state: login_state.encode))
        end
      end

      context 'with a tampered X-Forwarded-Host header' do
        it 'prevents open redirect attack' do
          request.headers['X-Forwarded-Host'] = 'http://this.is.not.my.host'

          get(:new)

          expect(response).to have_gitlab_http_status(302)
          expect(response).to redirect_to(oauth_geo_auth_url(host: secondary_node.url, state: login_state.encode))
        end
      end

      context 'without a tampered header' do
        it 'redirects to oauth_geo_auth_url' do
          get(:new)

          expect(response).to have_gitlab_http_status(302)
          expect(response).to redirect_to(oauth_geo_auth_url(host: secondary_node.url, state: login_state.encode))
        end
      end
    end
  end
end
