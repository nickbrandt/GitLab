# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'batch comments in merge request' do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-merge-request'
        end
      end
      let(:merge_request) do
        Resource::MergeRequest.fabricate_via_api! do |merge_request|
          merge_request.title = 'This is a merge request'
          merge_request.description = 'Great feature'
          merge_request.project = project
        end
      end

      it 'user submits, discards batch comments' do
        Flow::Login.sign_in

        merge_request.visit!

        Page::MergeRequest::Show.perform do |show|
          show.click_discussions_tab

          show.start_discussion("I'm starting a new discussion")
          expect(show).to have_content("I'm starting a new discussion")

          show.type_reply_to_discussion("Could you please check this?")
          show.comment_now
          expect(show).to have_content("Could you please check this?")
          expect(show).to have_content("0/1 thread resolved")

          show.type_reply_to_discussion("Could you also check that?")
          show.resolve_review_discussion
          show.start_review
          expect(show).to have_content("Could you also check that?")
          expect(show).to have_content("Finish review 1")

          show.click_diffs_tab

          show.add_comment_to_diff("Can you check this line of code?")
          show.comment_now
          expect(show).to have_content("Can you check this line of code?")

          show.type_reply_to_discussion("And this syntax as well?")
          show.resolve_review_discussion
          show.start_review
          expect(show).to have_content("And this syntax as well?")
          expect(show).to have_content("Finish review 2")

          show.submit_pending_reviews
          expect(show).to have_content("2/2 threads resolved")

          show.toggle_comments
          show.type_reply_to_discussion("Unresolving this discussion")
          show.unresolve_review_discussion
          show.comment_now
          expect(show).to have_content("1/2 threads resolved")
        end

        Page::MergeRequest::Show.perform do |show|
          show.click_discussions_tab

          show.type_reply_to_discussion("Planning to discard this comment")
          show.start_review

          expect(show).to have_content("Finish review 1")
          show.discard_pending_reviews

          expect(show).not_to have_content("Planning to discard this comment")
        end

        # Overwrite the added file to create a system note as required to
        # trigger the bug described here: https://gitlab.com/gitlab-org/gitlab/issues/32157
        commit_message = 'Update file'
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = commit_message
          commit.branch = merge_request.source_branch
          commit.update_files(
            [
              {
                file_path: merge_request.file_name,
                content: "File updated"
              }
            ]
          )
        end
        project.wait_for_push(commit_message)

        merge_request.visit!
        Page::MergeRequest::Show.perform do |show|
          show.resolve_discussion_at_index(1)

          expect(show).to have_content("2/2 threads resolved")
        end
      end
    end
  end
end
