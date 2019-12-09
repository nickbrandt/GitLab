# frozen_string_literal: true

require 'spec_helper'

describe Groups::Security::ComplianceDashboardsController do
  let(:user) { create(:user) }
  let(:group) { create(:group) }

  before do
    sign_in(user)
  end

  describe 'GET show' do
    subject { get :show, params: { group_id: group.to_param } }

    context 'when compliance dashboard feature is enabled' do
      before do
        stub_licensed_features(group_level_compliance_dashboard: true)
      end

      context 'and user is allowed to access group compliance dashboard' do
        render_views

        before do
          group.add_owner(user)
        end

        it { is_expected.to have_gitlab_http_status(200) }

        context 'when there are no merge requests' do
          it 'renders empty state' do
            subject
            expect(response.body).to have_css("div.empty-state")
          end
        end

        context 'when there are merge requests' do
          let(:project) { create(:project, namespace: group) }

          let(:mr_1) { create(:merge_request, source_project: project, state: :merged) }
          let(:mr_2) { create(:merge_request, source_project: project, source_branch: 'A', state: :merged) }

          before do
            mr_1.metrics.update!(merged_at: 20.minutes.ago)
          end

          it 'renders merge request' do
            subject
            expect(response.body).to have_css(".merge-request-title.title")
          end
        end
      end

      context 'when user is not allowed to access group compliance dashboard' do
        it { is_expected.to have_gitlab_http_status(404) }
      end
    end

    context 'when compliance dashboard feature is disabled' do
      it { is_expected.to have_gitlab_http_status(404) }
    end
  end
end
