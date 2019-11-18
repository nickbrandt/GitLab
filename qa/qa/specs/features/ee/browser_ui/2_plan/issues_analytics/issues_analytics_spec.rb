# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'Issues analytics' do
      let(:issue) do
        Resource::Issue.fabricate_via_api! do |issue|
          issue.title = 'Issue to test Issues Analytics'
        end
      end

      before do
        Flow::Login.sign_in
      end

      it 'displays a graph' do
        page.visit("#{issue.project.group.web_url}/-/issues_analytics")

        EE::Page::Group::IssuesAnalytics.perform do |issues_analytics|
          expect(issues_analytics.graph).to be_visible
        end
      end
    end
  end
end
