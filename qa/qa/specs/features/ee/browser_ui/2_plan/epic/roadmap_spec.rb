# frozen_string_literal: true

module QA
  # https://gitlab.com/gitlab-org/gitlab-ee/issues/13360
  context 'Plan', :quarantine do
    describe 'Epics roadmap' do
      let(:epic) do
        EE::Resource::Epic.fabricate_via_api! do |epic|
          current_date = DateTime.now
          current_date_yyyy_mm_dd = current_date.strftime("%Y/%m/%d")
          next_month_date_yyyy_mm_dd = current_date.next_month.strftime("%Y/%m/%d")

          epic.title = 'Epic created via API to test roadmap'
          epic.start_date_is_fixed = true
          epic.start_date_fixed = current_date_yyyy_mm_dd
          epic.due_date_is_fixed = true
          epic.due_date_fixed = next_month_date_yyyy_mm_dd
        end
      end

      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)
      end

      it 'presents epic on roadmap' do
        page.visit("#{epic.group.web_url}/-/roadmap")

        EE::Page::Group::Roadmap.perform do |roadmap|
          expect(roadmap.epic_present?(epic)).to be_truthy
        end
      end
    end
  end
end
