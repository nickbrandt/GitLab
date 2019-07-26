# frozen_string_literal: true
require 'spec_helper'

describe API::ConanPackages do
  set(:guest) { create(:user) }
  let(:api_user) { guest }

  before do
    stub_licensed_features(packages: true)
  end

  describe 'GET /api/v4/packages/conan/v1/ping' do
    let(:url) { '/packages/conan/v1/ping' }

    subject { get api(url, api_user) }

    context 'feature flag disabled' do
      before do
        stub_feature_flags(conan_package_registry: false)
      end

      it 'returns not found' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'feature flag enabled' do
      it 'rejects with no authorization' do
        subject

        expect(response).to have_gitlab_http_status(401)
      end

      context 'packages feature disabled' do
        it 'fails' do
          stub_packages_setting(enabled: false)
          subject

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end
end
