# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::MergeRequestJiraIssue do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository, creator: user) }
  let_it_be_with_reload(:merge_request) { create(:merge_request, author: user, source_project: project, target_project: project) }

  describe 'GET /projects/:id/merge_requests/:merge_request_iid/jira_issue' do
    let(:url) { "/projects/#{project.id}/merge_requests/#{merge_request.iid}/jira_issue" }

    subject { get api(url, current_user) }

    shared_examples 'not found' do
      specify do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when feature is available' do
      before do
        stub_licensed_features(jira_issue_association_enforcement: true)
        stub_feature_flags(jira_issue_association_on_merge_request: true)
      end

      context 'user does not have access' do
        let_it_be(:unauthorized_user) { create(:user) }
        let(:current_user) { unauthorized_user }

        before do
          project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
        end

        it 'responds with forbidden' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'user has access' do
        let(:current_user) { user }

        context 'when jira issue is not required for merge' do
          before do
            project.create_project_setting(prevent_merge_without_jira_issue: false)
          end

          it_behaves_like 'not found'
        end

        context 'when jira issue is required for merge' do
          before do
            project.create_project_setting(prevent_merge_without_jira_issue: true)
          end

          it 'responds with not found' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
          end

          context 'when Jira issue is not provided in MR title/description' do
            it 'responds with not found' do
              subject

              expect(json_response["is_present"]).to eq(false)
            end
          end

          context 'when Jira issue is provided in MR title' do
            before do
              merge_request.update!(title: 'Fix PRODUCT-1234')
            end

            it 'responds with not found' do
              subject

              expect(json_response["is_present"]).to eq(true)
            end
          end

          context 'when Jira issue is provided in MR description' do
            before do
              merge_request.update!(description: 'Jira issue associated: PRODUCT-1234')
            end

            it 'responds with not found' do
              subject

              expect(json_response["is_present"]).to eq(true)
            end
          end
        end
      end
    end

    context 'when feature is not available' do
      using RSpec::Parameterized::TableSyntax

      let(:current_user) { user }

      where(:licensed, :feature_flag) do
        false | true
        true  | false
        false | false
      end

      with_them do
        before do
          stub_licensed_features(jira_issue_association_enforcement: licensed)
          stub_feature_flags(jira_issue_association_on_merge_request: feature_flag)
        end

        it_behaves_like 'not found'
      end
    end
  end
end
