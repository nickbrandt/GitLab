# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

describe Notify do
  include EmailSpec::Helpers
  include EmailSpec::Matchers
  include EmailHelpers
  include RepoHelpers

  include_context 'gitlab email notification'

  set(:user) { create(:user) }
  set(:current_user) { create(:user, email: "current@email.com") }
  set(:assignee) { create(:user, email: 'assignee@example.com', name: 'John Doe') }
  set(:assignee2) { create(:user, email: 'assignee2@example.com', name: 'Jane Doe') }

  set(:merge_request) do
    create(:merge_request, source_project: project,
                           target_project: project,
                           author: current_user,
                           assignees: [assignee, assignee2],
                           description: 'Awesome description')
  end

  set(:issue) do
    create(:issue, author: current_user,
                   assignees: [assignee],
                   project: project,
                   description: 'My awesome description!')
  end

  set(:project2) { create(:project, :repository) }
  set(:merge_request_without_assignee) do
    create(:merge_request, source_project: project2,
                           author: current_user,
                           description: 'Awesome description')
  end

  describe '.note_design_email' do
    set(:design) { create(:design, :with_file) }
    set(:recipient) { create(:user) }
    set(:note) do
      create(:diff_note_on_design,
         noteable: design,
         project: design.project,
         note: "Hello #{recipient.to_reference}")
    end

    let(:header_name) { 'X-Gitlab-DesignManagement-Design-ID' }
    let(:refer_to_design) do
      have_attributes(subject: a_string_including(design.filename))
    end

    subject { described_class.note_design_email(recipient.id, note.id) }

    it { is_expected.to have_header(header_name, design.id.to_s) }

    it { is_expected.to have_body_text(design.filename) }

    it { is_expected.to refer_to_design }
  end

  context 'for a project' do
    context 'for service desk issues' do
      before do
        issue.update!(service_desk_reply_to: 'service.desk@example.com')
      end

      describe 'thank you email' do
        subject { described_class.service_desk_thank_you_email(issue.id) }

        it_behaves_like 'an unsubscribeable thread'

        it 'has the correct recipient' do
          is_expected.to deliver_to('service.desk@example.com')
        end

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(issue, include_project: false, reply: true)
            is_expected.to have_body_text("Thank you for your support request! We are tracking your request as ticket #{issue.to_reference}, and will respond as soon as we can.")
          end
        end
      end

      describe 'new note email' do
        set(:first_note) { create(:discussion_note_on_issue, note: 'Hello world') }

        subject { described_class.service_desk_new_note_email(issue.id, first_note.id) }

        it_behaves_like 'an unsubscribeable thread'

        it 'has the correct recipient' do
          is_expected.to deliver_to('service.desk@example.com')
        end

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(issue, include_project: false, reply: true)
            is_expected.to have_body_text(first_note.note)
          end
        end
      end
    end

    context 'for merge requests' do
      describe "that are new with approver" do
        before do
          create(:approver, target: merge_request)
        end

        subject do
          described_class.new_merge_request_email(assignee.id, merge_request.id)
        end

        it "contains the approvers list" do
          is_expected.to have_body_text %r[#{merge_request.approvers.first.user.name}]
        end
      end

      describe 'that are approved' do
        let(:last_approver) { create(:user) }

        subject { described_class.approved_merge_request_email(recipient.id, merge_request.id, last_approver.id) }

        before do
          merge_request.approvals.create(user: assignee)
          merge_request.approvals.create(user: last_approver)
        end

        it_behaves_like 'a multiple recipients email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { merge_request }
        end
        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like 'an unsubscribeable thread'

        it 'is sent as the last approver' do
          sender = subject.header[:from].addrs[0]
          expect(sender.display_name).to eq(last_approver.name)
          expect(sender.address).to eq(gitlab_sender)
        end

        it 'has the correct subject' do
          is_expected.to have_attributes(
            subject: a_string_including("#{merge_request.title} (#{merge_request.to_reference})")
          )
        end

        it 'contains the new status' do
          is_expected.to have_body_text('approved')
        end

        it 'contains a link to the merge request' do
          is_expected.to have_body_text("#{project_merge_request_path project, merge_request}")
        end

        it 'contains the names of all of the approvers' do
          names = merge_request.approvals.map { |a| a.user.name }

          aggregate_failures do
            names.each { |name| is_expected.to have_body_text(name) }
          end
        end

        it 'contains the names of all assignees' do
          names = merge_request.assignees.map(&:name)

          aggregate_failures do
            names.each { |name| is_expected.to have_body_text(name) }
          end
        end

        context 'when merge request has no assignee' do
          before do
            merge_request.update(assignees: [])
          end

          it 'does not show the assignee' do
            is_expected.not_to have_body_text 'Assignee'
          end
        end
      end

      describe 'that are unapproved' do
        let(:last_unapprover) { create(:user) }

        subject { described_class.unapproved_merge_request_email(recipient.id, merge_request.id, last_unapprover.id) }

        before do
          merge_request.approvals.create(user: assignee)
        end

        it_behaves_like 'a multiple recipients email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { merge_request }
        end
        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like 'an unsubscribeable thread'

        it 'is sent as the last unapprover' do
          sender = subject.header[:from].addrs[0]
          expect(sender.display_name).to eq(last_unapprover.name)
          expect(sender.address).to eq(gitlab_sender)
        end

        it 'has the correct subject' do
          is_expected.to have_attributes(
            subject: a_string_including("#{merge_request.title} (#{merge_request.to_reference})")
          )
        end

        it 'contains the new status' do
          is_expected.to have_body_text('unapproved')
        end

        it 'contains a link to the merge request' do
          is_expected.to have_body_text("#{project_merge_request_path project, merge_request}")
        end

        it 'contains the names of all of the approvers' do
          names = merge_request.approvals.map { |a| a.user.name }

          aggregate_failures do
            names.each { |name| is_expected.to have_body_text(name) }
          end
        end

        it 'contains the names of all assignees' do
          names = merge_request.assignees.map(&:name)

          aggregate_failures do
            names.each { |name| is_expected.to have_body_text(name) }
          end
        end
      end
    end

    context 'for merge requests without assignee' do
      describe 'that are unapproved' do
        let(:last_unapprover) { create(:user) }

        subject { described_class.unapproved_merge_request_email(recipient.id, merge_request_without_assignee.id, last_unapprover.id) }

        before do
          merge_request_without_assignee.approvals.create(user: merge_request_without_assignee.assignees.first)
        end

        it 'contains the new status' do
          is_expected.to have_body_text('unapproved')
        end
      end
    end
  end

  context 'for a group' do
    describe 'for epics' do
      set(:group) { create(:group) }
      set(:epic) { create(:epic, group: group) }

      context 'that are new' do
        subject { described_class.new_epic_email(recipient.id, epic.id) }

        it_behaves_like 'an epic email starting a new thread with reply-by-email enabled' do
          let(:model) { epic }
        end
        it_behaves_like 'it should show Gmail Actions View Epic link'
        it_behaves_like 'an unsubscribeable thread'

        it 'has the correct subject and body' do
          prefix = "#{epic.group.name} | "
          suffix = "#{epic.title} (#{epic.to_reference})"

          aggregate_failures do
            is_expected.to have_subject [prefix, suffix].compact.join
            is_expected.to have_body_text(group_epic_path(group, epic))
          end
        end

        context 'got deleted before notification' do
          subject { described_class.new_epic_email(recipient.id, 0) }

          it 'does not send email' do
            expect(subject.message).to be_a_kind_of ActionMailer::Base::NullMail
          end
        end
      end

      context 'for epic notes' do
        set(:note) { create(:note, project: nil, noteable: epic) }
        let(:note_author) { note.author }
        let(:epic_note_path) { group_epic_path(group, epic, anchor: "note_#{note.id}") }

        subject { described_class.note_epic_email(recipient.id, note.id) }

        it_behaves_like 'a note email'

        it_behaves_like 'an unsubscribeable thread'

        it 'has the characteristics of a threaded reply' do
          host = Gitlab.config.gitlab.host
          route_key = "#{epic.class.model_name.singular_route_key}_#{epic.id}"

          aggregate_failures do
            is_expected.to have_header('Message-ID', /\A<.*@#{host}>\Z/)
            is_expected.to have_header('In-Reply-To', "<#{route_key}@#{host}>")
            is_expected.to have_header('References',  /\A<reply\-.*@#{host}> <#{route_key}@#{host}>\Z/ )
            is_expected.to have_subject(/^Re: /)
          end
        end

        context 'when reply-by-email is enabled with incoming address with %{key}' do
          it 'has a Reply-To header' do
            is_expected.to have_header 'Reply-To', /<reply+(.*)@#{Gitlab.config.gitlab.host}>\Z/
          end
        end

        it_behaves_like 'it should show Gmail Actions View Epic link'

        it 'has the correct subject and body' do
          prefix = "Re: #{epic.group.name} | "
          suffix = "#{epic.title} (#{epic.to_reference})"

          aggregate_failures do
            is_expected.to have_subject [prefix, suffix].compact.join
            is_expected.to have_body_text(epic_note_path)
          end
        end
      end
    end
  end

  describe 'merge request reviews' do
    let!(:review) { create(:review, project: project, merge_request: merge_request) }
    let!(:notes) { create_list(:note, 3, review: review, project: project, author: review.author, noteable: merge_request) }

    subject { described_class.new_review_email(recipient.id, review.id) }

    it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
      let(:model) { review.merge_request }
    end
    it_behaves_like 'it should show Gmail Actions View Merge request link'
    it_behaves_like 'an unsubscribeable thread'

    it 'is sent to the given recipient as the author' do
      sender = subject.header[:from].addrs[0]

      aggregate_failures do
        expect(sender.display_name).to eq(review.author_name)
        expect(sender.address).to eq(gitlab_sender)
        expect(subject).to deliver_to(recipient.notification_email)
      end
    end

    it 'contains the message from the notes of the review' do
      review.notes.each do |note|
        is_expected.to have_body_text note.note
      end
    end

    context 'when diff note' do
      let!(:notes) { create_list(:diff_note_on_merge_request, 3, review: review, project: project, author: review.author, noteable: merge_request) }

      it 'links to notes' do
        review.notes.each do |note|
          # Text part
          expect(subject.text_part.body.raw_source).to include(
            project_merge_request_url(project, merge_request, anchor: "note_#{note.id}")
          )
        end
      end
    end

    it 'contains review author name' do
      is_expected.to have_body_text review.author_name
    end

    it 'has the correct subject and body' do
      aggregate_failures do
        is_expected.to have_subject "Re: #{project.name} | #{merge_request.title} (#{merge_request.to_reference})"

        is_expected.to have_body_text project_merge_request_path(project, merge_request)
      end
    end
  end

  describe 'mirror was hard failed' do
    let(:project) { create(:project, :mirror, :import_hard_failed) }

    subject { described_class.mirror_was_hard_failed_email(project.id, user.id) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like "a user cannot unsubscribe through footer link"

    it 'has the correct subject and body' do
      is_expected.to have_subject("#{project.name} | Repository mirroring paused")
      is_expected.to have_body_text(project.full_path)
      is_expected.to have_body_text(project_settings_repository_url(project))
    end
  end

  describe 'mirror user changed' do
    let(:mirror_user) { create(:user) }
    let(:project) { create(:project, :mirror, mirror_user_id: mirror_user.id) }
    let(:new_mirror_user) { project.team.owners.first }

    subject { described_class.project_mirror_user_changed_email(new_mirror_user.id, mirror_user.name, project.id) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like "a user cannot unsubscribe through footer link"

    it 'has the correct subject and body' do
      is_expected.to have_subject("#{project.name} | Mirror user changed")
      is_expected.to have_body_text(project.full_path)
    end
  end

  describe 'admin notification' do
    let(:example_site_path) { root_path }
    let(:user) { create(:user) }

    subject { @email = described_class.send_admin_notification(user.id, 'Admin announcement', 'Text') }

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq("GitLab")
      expect(sender.address).to eq(gitlab_sender)
    end

    it 'is sent to recipient' do
      is_expected.to deliver_to user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject 'Admin announcement'
    end

    it 'includes unsubscribe link' do
      unsubscribe_link = "http://localhost/unsubscribes/#{Base64.urlsafe_encode64(user.email)}"
      is_expected.to have_body_text(unsubscribe_link)
    end
  end
end
