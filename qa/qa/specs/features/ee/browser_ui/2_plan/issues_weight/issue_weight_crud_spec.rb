# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'Issues weight CRUD operations' do
      let(:issue) do
        Resource::Issue.fabricate_via_api! do |issue|
          issue.title = 'issue-to-test-weight-crud-operations'
        end
      end

      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)
      end

      it 'adds, edits, and removes issue\'s weight' do
        issue.visit!

        weight_of_one = 1
        weight_of_two = 2

        Page::Project::Issue::Show.perform do |show|
          show.set_weight(weight_of_one)

          expect(show.weight_label_value).to have_content(weight_of_one)

          show.set_weight(weight_of_two)

          expect(show.weight_label_value).to have_content(weight_of_two)

          show.click_remove_weight_link

          expect(show.weight_no_value_content).to be_visible
          expect(show.weight_no_value_content).to have_content('None')
        end
      end
    end
  end
end
