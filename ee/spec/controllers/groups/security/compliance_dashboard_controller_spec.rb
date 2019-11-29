# frozen_string_literal: true

require 'spec_helper'

describe Groups::Security::ComplianceDashboardController do
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
        before do
          group.add_owner(user)
        end

        it { is_expected.to have_gitlab_http_status(200) }

        context 'when there are no merge requests' do
          render_views

          it 'renders empty state' do
            subject
            expect(response.body).to have_css("div.empty-state")
          end
        end

        context 'when there are merge requests from projects in group' do
          let(:project) { create(:project, namespace: group) }
          let(:project_2) { create(:project, namespace: group) }

          let(:mr_1) { create(:merge_request, source_project: project, state: :merged) }
          let(:mr_2) { create(:merge_request, source_project: project_2, state: :merged) }
          let(:mr_3) { create(:merge_request, source_project: project, source_branch: 'A', state: :merged) }
          let(:mr_4) { create(:merge_request, source_project: project_2, source_branch: 'A', state: :merged) }

          before do
            mr_1.metrics.update!(merged_at: 20.minutes.ago)
            mr_2.metrics.update!(merged_at: 40.minutes.ago)
            mr_3.metrics.update!(merged_at: 30.minutes.ago)
            mr_4.metrics.update!(merged_at: 50.minutes.ago)
          end

          it 'shows only most recent Merge Request from each project' do
            subject
            expect(assigns(:merge_requests)).to contain_exactly(mr_1, mr_2)
          end

          context 'when there are merge requests from projects in group and subgroups' do
            let(:subgroup) { create(:group, parent: group) }
            let(:sub_project) { create(:project, namespace: subgroup) }

            let(:mr_5) { create(:merge_request, source_project: sub_project, state: :merged) }
            let(:mr_6) { create(:merge_request, source_project: sub_project, state: :merged) }

            before do
              mr_5.metrics.update!(merged_at: 10.minutes.ago)
              mr_6.metrics.update!(merged_at: 30.minutes.ago)
            end

            xit 'shows only most recent Merge Request from each project' do
              subject
              expect(assigns(:merge_requests)).to eq([mr_5, mr_1, mr_2])
            end
          end
        end
      end

      context 'when user is not allowed to access group compliance dashboard' do
        it { is_expected.to have_gitlab_http_status(403) }
      end
    end

    context 'when security compliance feature is disabled' do
      it { is_expected.to have_gitlab_http_status(403) }
    end
  end
end
