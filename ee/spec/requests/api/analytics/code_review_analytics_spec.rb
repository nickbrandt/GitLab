# frozen_string_literal: true

require 'spec_helper'

describe API::Analytics::CodeReviewAnalytics do
  let(:current_user) { reporter }
  let(:group) { create(:group, :private) }
  let(:project) { create(:project, namespace: group) }
  let!(:reporter) do
    create(:user).tap { |u| project.add_reporter(u) }
  end
  let!(:guest) do
    create(:user).tap { |u| project.add_guest(u) }
  end

  describe 'GET code_review' do
    subject(:api_call) { get api("/analytics/code_review?project_id=#{project.id}", current_user) }

    it 'is successful' do
      api_call

      expect(response).to have_gitlab_http_status(200)
    end

    context 'when feature is disabled' do
      before do
        stub_feature_flags(code_review_analytics: false)
      end

      it 'is not found' do
        api_call

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when user has no authorization' do
      let(:current_user) { guest }

      it 'is not authorized' do
        api_call

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when feature is not available in plan' do
      before do
        stub_licensed_features(code_review_analytics: false)
      end

      it 'is not found' do
        api_call

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when project_id is not specified' do
      subject(:api_call) { get api("/analytics/code_review", current_user) }

      it 'is not found' do
        api_call

        expect(response).to have_gitlab_http_status(400)
      end
    end
  end
end
