# frozen_string_literal: true

require 'spec_helper'

describe Analytics::CodeAnalyticsController do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  before do
    group.add_reporter(current_user)
    stub_licensed_features(code_analytics: true)
    sign_in(current_user)
  end

  describe 'GET show' do
    subject { get :show, format: :html, params: {} }

    it 'renders successfully without license' do
      stub_feature_flags(Gitlab::Analytics::CODE_ANALYTICS_FEATURE_FLAG => true)
      stub_licensed_features(code_analytics: false)

      subject

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'renders successfully with license' do
      stub_feature_flags(Gitlab::Analytics::CODE_ANALYTICS_FEATURE_FLAG => true)
      stub_licensed_features(code_analytics: true)

      subject

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'renders `not_found` when feature flag is disabled' do
      stub_licensed_features(code_analytics: true)
      stub_feature_flags(Gitlab::Analytics::CODE_ANALYTICS_FEATURE_FLAG => false)

      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET `show` as json' do
    let(:params) { { group_id: group.full_path, project_id: project.full_path, file_count: 15 } }

    subject { get :show, format: :json, params: params }

    it 'renders `forbidden` without proper license' do
      stub_feature_flags(Gitlab::Analytics::CODE_ANALYTICS_FEATURE_FLAG => true)
      stub_licensed_features(code_analytics: false)

      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'renders `not_found` when feature flag is disabled' do
      stub_licensed_features(code_analytics: true)
      stub_feature_flags(Gitlab::Analytics::CODE_ANALYTICS_FEATURE_FLAG => false)

      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context 'when user has lower access than reporter' do
      before do
        stub_feature_flags(Gitlab::Analytics::CODE_ANALYTICS_FEATURE_FLAG => true)

        GroupMember.where(user: current_user).delete_all
        group.add_guest(current_user)
      end

      it 'renders `forbidden`' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when valid parameters are given' do
      let_it_be(:file_commit) { create(:analytics_repository_file_commit, committed_date: 2.days.ago, project: project) }

      it { expect(response).to be_successful }

      it 'renders files with commit count' do
        subject

        first_repository_file = json_response.first
        expect(first_repository_file['name']).to eq(file_commit.analytics_repository_file.file_path)
        expect(first_repository_file['count']).to eq(file_commit.commit_count)
      end
    end

    context 'when invalid parameters are given' do
      context 'when `file_count` is missing' do
        before do
          params.delete(:file_count)
        end

        it 'renders error response' do
          subject

          expect(json_response['errors']['file_count']).not_to be_empty
        end
      end

      context 'when `file_count` is over the limit' do
        before do
          params[:file_count] = Analytics::CodeAnalytics::RepositoryFileCommit::MAX_FILE_COUNT + 1
        end

        it 'renders error response' do
          subject

          expect(json_response['errors']['file_count']).not_to be_empty
        end
      end
    end
  end
end
