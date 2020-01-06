# frozen_string_literal: true

require 'spec_helper'

describe Projects::Analytics::CodeReviewsController, type: :request do
  let(:user) { create :user }
  let(:project) { create(:project) }

  before do
    project.add_guest(user)
    login_as user
    stub_feature_flags(code_review_analytics: true)
  end

  describe 'GET /*namespace_id/:project_id/analytics/code_reviews' do
    context 'with code_review_analytics included in plan' do
      it 'is success' do
        get project_analytics_code_reviews_path(project)

        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'without code_review_analytics in plan' do
      before do
        stub_licensed_features(code_review_analytics: false)
      end

      it 'is not found' do
        get project_analytics_code_reviews_path(project)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
