# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Analytics::CoverageReportsController do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }

  context 'without permissions' do
    before do
      sign_in(user)
    end

    describe 'GET index' do
      it 'responds 403' do
        get :index, params: { group_id: group.name, format: :csv }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  context 'with permissions' do
    before do
      group.add_owner(user)
      sign_in(user)
    end

    context 'without a license' do
      before do
        stub_licensed_features(group_coverage_reports: false)
      end

      describe 'GET index' do
        it 'responds 403 because the feature is not licensed' do
          get :index, params: { group_id: group.name, format: :csv }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'with the feature flag shut off' do
      before do
        stub_licensed_features(group_coverage_reports: true)
        stub_feature_flags(group_coverage_reports: false)
      end

      describe 'GET index' do
        it 'responds 403 because the feature is not licensed' do
          get :index, params: { group_id: group.name, format: :csv }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    describe 'GET index' do
      before do
        stub_licensed_features(group_coverage_reports: true)
      end

      it 'responds 200 OK' do
        get :index, params: { group_id: group.name, format: :csv }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
