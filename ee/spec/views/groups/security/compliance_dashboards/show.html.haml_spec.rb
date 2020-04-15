# frozen_string_literal: true

require 'spec_helper'

describe 'groups/security/compliance_dashboards/show.html.haml' do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }

  before do
    group.add_owner(user)
    stub_licensed_features(group_level_compliance_dashboard: true)
  end

  context 'when there are no merge requests' do
    it 'renders empty state' do
      render

      expect(rendered).to have_css('div', class: 'empty-state merge-requests')
      expect(rendered).not_to have_css('div', class: 'compliance-dashboard')
    end
  end

  context 'when there are merge requests' do
    let(:merge_request) { create(:merge_request, source_project: project, state: :merged) }
    let(:current_user) { user }

    before do
      merge_request.metrics.update!(merged_at: 10.minutes.ago)
      assign(:merge_requests, Kaminari.paginate_array([merge_request]).page(0))
    end

    it 'renders merge requests' do
      render

      expect(rendered).to have_link(merge_request.title)
      expect(rendered).not_to have_css('div', class: 'empty-state merge-requests')
    end

    it 'renders merge requests with time merged tooltip' do
      render

      expect(rendered).to have_css('time', class: 'js-timeago')
    end

    context 'with no pipeline' do
      it 'renders no pipeline status icon' do
        render

        expect(rendered).not_to have_css('.ci-status-link')
      end
    end

    context 'with a pipeline' do
      context 'and the user is logged in' do
        before do
          sign_in(current_user)
        end

        ::Ci::Pipeline.bridgeable_statuses.each do |status|
          context "and the status is #{status}" do
            let!(:pipeline) { create(:ci_empty_pipeline, status: status, project: project, head_pipeline_of: merge_request) }

            it "renders the pipeline status icon for #{status}" do
              render

              expect(rendered).to have_css(".ci-status-link.ci-status-icon-#{status}")
            end
          end
        end
      end

      context 'and the user is not logged in' do
        let(:status) { ::Ci::Pipeline.bridgeable_statuses.first }
        let!(:pipeline) { create(:ci_empty_pipeline, status: status, project: project, head_pipeline_of: merge_request) }

        it "does not render a pipeline status icon" do
          render

          expect(rendered).not_to have_css(".ci-status-link.ci-status-icon")
        end
      end
    end

    context 'with no approvers' do
      it 'renders the message "No approvers"' do
        render

        expect(rendered).to have_css("li span", text: 'No approvers')
      end
    end

    context 'with a single approvers' do
      let(:approver_1) { create(:user) }
      let!(:approval_rule) { create :approval_merge_request_rule, merge_request: merge_request, users: [approver_1] }
      let!(:approval) { create :approval, merge_request: merge_request, user: approver_1 }

      before do
        project.add_developer(approver_1)
      end

      it 'renders a single approver avatar link' do
        render

        expect(rendered).to have_css('a', class: 'author-link', count: 1)
        expect(rendered).to have_link(approver_1.name)
      end
    end

    context 'with more than two approvers' do
      let(:approver_1) { create(:user) }
      let(:approver_2) { create(:user) }
      let(:approver_3) { create(:user) }
      let!(:approval_1) { create :approval, merge_request: merge_request, user: approver_1 }
      let!(:approval_2) { create :approval, merge_request: merge_request, user: approver_2 }
      let!(:approval_3) { create :approval, merge_request: merge_request, user: approver_3 }

      before do
        project.add_developer(approver_1)
        project.add_developer(approver_2)
        project.add_developer(approver_3)
      end

      it 'renders the two latest approvers\'s avatar links' do
        render

        expect(rendered).to have_css('a', class: 'author-link', count: 2)
      end

      it 'renders a tooltip for additional approvers' do
        render

        expect(rendered).to have_css('span', class: 'avatar-counter', text: '+ 1')
      end
    end
  end
end
