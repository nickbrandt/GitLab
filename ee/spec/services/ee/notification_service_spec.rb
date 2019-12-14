# frozen_string_literal: true

require 'spec_helper'

describe EE::NotificationService, :mailer do
  include EmailSpec::Matchers
  include NotificationHelpers
  include DesignManagementTestHelpers

  let(:subject) { NotificationService.new }

  let(:mailer) { double(deliver_later: true) }

  context 'when notified of a new design diff note' do
    set(:design) { create(:design, :with_file) }
    set(:project) { design.project }
    set(:dev) { create(:user) }
    set(:stranger) { create(:user) }
    set(:note) do
      create(:diff_note_on_design,
         noteable: design,
         project: project,
         note: "Hello #{dev.to_reference}, G'day #{stranger.to_reference}")
    end

    context 'design management is enabled' do
      before do
        enable_design_management
        project.add_developer(dev)
        allow(Notify).to receive(:note_design_email) { mailer }
      end

      it 'sends new note notifications' do
        expect(subject).to receive(:send_new_note_notifications).with(note)

        subject.new_note(note)
      end

      it 'sends a mail to the developer' do
        expect(Notify)
          .to receive(:note_design_email).with(dev.id, note.id, "mentioned")

        subject.new_note(note)
      end

      it 'does not notify non-developers' do
        expect(Notify)
          .not_to receive(:note_design_email).with(stranger.id, note.id)

        subject.new_note(note)
      end
    end

    context 'design management is disabled' do
      it 'does not notify the user' do
        expect(Notify).not_to receive(:note_design_email)

        subject.new_note(note)
      end
    end
  end

  context 'service desk issues' do
    before do
      allow(Notify).to receive(:service_desk_new_note_email)
                         .with(Integer, Integer).and_return(mailer)

      allow(::EE::Gitlab::ServiceDesk).to receive(:enabled?).and_return(true)
      allow(::Gitlab::IncomingEmail).to receive(:enabled?) { true }
      allow(::Gitlab::IncomingEmail).to receive(:supports_wildcard?) { true }
    end

    def should_email!
      expect(Notify).to receive(:service_desk_new_note_email)
        .with(issue.id, note.id)
    end

    def should_not_email!
      expect(Notify).not_to receive(:service_desk_new_note_email)
    end

    def execute!
      subject.new_note(note)
    end

    def self.it_should_email!
      it 'sends the email' do
        should_email!
        execute!
      end
    end

    def self.it_should_not_email!
      it 'doesn\'t send the email' do
        should_not_email!
        execute!
      end
    end

    let(:issue) { create(:issue, author: User.support_bot) }
    let(:project) { issue.project }
    let(:note) { create(:note, noteable: issue, project: project) }

    context 'a non-service-desk issue' do
      it_should_not_email!
    end

    context 'a service-desk issue' do
      before do
        issue.update!(service_desk_reply_to: 'service.desk@example.com')
        project.update!(service_desk_enabled: true)
      end

      it_should_email!

      context 'where the project has disabled the feature' do
        before do
          project.update(service_desk_enabled: false)
        end

        it_should_not_email!
      end

      context 'when the license doesn\'t allow service desk' do
        before do
          allow(::EE::Gitlab::ServiceDesk).to receive(:enabled?).and_return(false)
        end

        it_should_not_email!
      end

      context 'when the support bot has unsubscribed' do
        before do
          issue.unsubscribe(User.support_bot, project)
        end

        it_should_not_email!
      end
    end
  end

  context 'new review' do
    let(:project) { create(:project, :repository) }
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:reviewer) { create(:user) }
    let(:merge_request) { create(:merge_request, source_project: project, assignees: [user, user2], author: create(:user)) }
    let(:review) { create(:review, merge_request: merge_request, project: project, author: reviewer) }
    let(:note) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, author: reviewer, review: review) }

    before do
      build_team(review.project, merge_request)
      project.add_maintainer(merge_request.author)
      project.add_maintainer(reviewer)
      merge_request.assignees.each { |assignee| project.add_maintainer(assignee) }

      create(:diff_note_on_merge_request,
             project: project,
             noteable: merge_request,
             author: reviewer,
             review: review,
             note: "cc @mention")
    end

    it 'sends emails' do
      expect(Notify).not_to receive(:new_review_email).with(review.author.id, review.id)
      expect(Notify).not_to receive(:new_review_email).with(@unsubscriber.id, review.id)
      merge_request.assignee_ids.each do |assignee_id|
        expect(Notify).to receive(:new_review_email).with(assignee_id, review.id).and_call_original
      end
      expect(Notify).to receive(:new_review_email).with(merge_request.author.id, review.id).and_call_original
      expect(Notify).to receive(:new_review_email).with(@u_watcher.id, review.id).and_call_original
      expect(Notify).to receive(:new_review_email).with(@u_mentioned.id, review.id).and_call_original
      expect(Notify).to receive(:new_review_email).with(@subscriber.id, review.id).and_call_original
      expect(Notify).to receive(:new_review_email).with(@watcher_and_subscriber.id, review.id).and_call_original
      expect(Notify).to receive(:new_review_email).with(@subscribed_participant.id, review.id).and_call_original

      subject.new_review(review)
    end

    it_behaves_like 'project emails are disabled' do
      let(:notification_target)  { review }
      let(:notification_trigger) { subject.new_review(review) }

      around do |example|
        perform_enqueued_jobs { example.run }
      end
    end

    def build_team(project, merge_request)
      @u_watcher               = create_global_setting_for(create(:user), :watch)
      @u_participating         = create_global_setting_for(create(:user), :participating)
      @u_participant_mentioned = create_global_setting_for(create(:user, username: 'participant'), :participating)
      @u_disabled              = create_global_setting_for(create(:user), :disabled)
      @u_mentioned             = create_global_setting_for(create(:user, username: 'mention'), :mention)
      @u_committer             = create(:user, username: 'committer')
      @u_not_mentioned         = create_global_setting_for(create(:user, username: 'regular'), :participating)
      @u_outsider_mentioned    = create(:user, username: 'outsider')
      @u_custom_global         = create_global_setting_for(create(:user, username: 'custom_global'), :custom)

      # subscribers
      @subscriber = create :user
      @unsubscriber = create :user
      @subscribed_participant = create_global_setting_for(create(:user, username: 'subscribed_participant'), :participating)
      @watcher_and_subscriber = create_global_setting_for(create(:user), :watch)

      # User to be participant by default
      # This user does not contain any record in notification settings table
      # It should be treated with a :participating notification_level
      @u_lazy_participant = create(:user, username: 'lazy-participant')

      @u_guest_watcher = create_user_with_notification(:watch, 'guest_watching')
      @u_guest_custom = create_user_with_notification(:custom, 'guest_custom')

      project.add_maintainer(@u_watcher)
      project.add_maintainer(@u_participating)
      project.add_maintainer(@u_participant_mentioned)
      project.add_maintainer(@u_disabled)
      project.add_maintainer(@u_mentioned)
      project.add_maintainer(@u_committer)
      project.add_maintainer(@u_not_mentioned)
      project.add_maintainer(@u_lazy_participant)
      project.add_maintainer(@u_custom_global)
      project.add_maintainer(@subscriber)
      project.add_maintainer(@unsubscriber)
      project.add_maintainer(@subscribed_participant)
      project.add_maintainer(@watcher_and_subscriber)

      merge_request.subscriptions.create(user: @unsubscribed_mentioned, subscribed: false)
      merge_request.subscriptions.create(user: @subscriber, subscribed: true)
      merge_request.subscriptions.create(user: @subscribed_participant, subscribed: true)
      merge_request.subscriptions.create(user: @unsubscriber, subscribed: false)
      # Make the watcher a subscriber to detect dupes
      merge_request.subscriptions.create(user: @watcher_and_subscriber, subscribed: true)
    end
  end

  describe 'mirror hard failed' do
    let(:user) { create(:user) }

    context 'when the project has invited members' do
      let(:project) { create(:project, :mirror, :import_hard_failed) }
      let!(:project_member) { create(:project_member, :invited, project: project) }

      it 'sends email' do
        expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, project.owner.id).and_call_original

        subject.mirror_was_hard_failed(project)
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { project }
        let(:notification_trigger) { subject.mirror_was_hard_failed(project) }

        around do |example|
          perform_enqueued_jobs { example.run }
        end
      end
    end

    context 'when user is owner' do
      let(:project) { create(:project, :mirror, :import_hard_failed) }

      it 'sends email' do
        expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, project.owner.id).and_call_original

        subject.mirror_was_hard_failed(project)
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { project }
        let(:notification_trigger) { subject.mirror_was_hard_failed(project) }

        around do |example|
          perform_enqueued_jobs { example.run }
        end
      end

      context 'when owner is blocked' do
        it 'does not send email' do
          project.owner.block!

          expect(Notify).not_to receive(:mirror_was_hard_failed_email)

          subject.mirror_was_hard_failed(project)
        end

        context 'when project belongs to group' do
          it 'does not send email to the blocked owner' do
            blocked_user = create(:user, :blocked)

            group = create(:group, :public)
            group.add_owner(blocked_user)
            group.add_owner(user)

            project = create(:project, :mirror, :import_hard_failed, namespace: group)

            expect(Notify).not_to receive(:mirror_was_hard_failed_email).with(project.id, blocked_user.id).and_call_original
            expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, user.id).and_call_original

            subject.mirror_was_hard_failed(project)
          end
        end
      end
    end

    context 'when user is maintainer' do
      it 'sends email' do
        project = create(:project, :mirror, :import_hard_failed)
        project.add_maintainer(user)

        expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, project.owner.id).and_call_original
        expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, user.id).and_call_original

        subject.mirror_was_hard_failed(project)
      end
    end

    context 'when user is not owner nor maintainer' do
      it 'does not send email' do
        project = create(:project, :mirror, :import_hard_failed)
        project.add_developer(user)

        expect(Notify).not_to receive(:mirror_was_hard_failed_email).with(project.id, user.id).and_call_original
        expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, project.creator.id).and_call_original

        subject.mirror_was_hard_failed(project)
      end

      context 'when user is group owner' do
        it 'sends email' do
          group = create(:group, :public) do |group|
            group.add_owner(user)
          end

          project = create(:project, :mirror, :import_hard_failed, namespace: group)

          expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, user.id).and_call_original

          subject.mirror_was_hard_failed(project)
        end
      end

      context 'when user is group maintainer' do
        it 'sends email' do
          group = create(:group, :public) do |group|
            group.add_maintainer(user)
          end

          project = create(:project, :mirror, :import_hard_failed, namespace: group)

          expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, user.id).and_call_original

          subject.mirror_was_hard_failed(project)
        end
      end
    end
  end

  context 'mirror user changed' do
    let(:mirror_user) { create(:user) }
    let(:project) { create(:project, :mirror, mirror_user_id: mirror_user.id) }
    let(:new_mirror_user) { project.team.owners.first }

    it 'sends email' do
      expect(Notify).to receive(:project_mirror_user_changed_email).with(new_mirror_user.id, mirror_user.name, project.id).and_call_original

      subject.project_mirror_user_changed(new_mirror_user, mirror_user.name, project)
    end

    it_behaves_like 'project emails are disabled' do
      let(:notification_target)  { project }
      let(:notification_trigger) { subject.project_mirror_user_changed(new_mirror_user, mirror_user.name, project) }

      around do |example|
        perform_enqueued_jobs { example.run }
      end
    end
  end

  describe '#prometheus_alerts_fired' do
    let!(:project) { create(:project) }
    let!(:prometheus_alert) { create(:prometheus_alert, project: project) }
    let!(:master) { create(:user) }
    let!(:developer) { create(:user) }

    before do
      project.add_master(master)
    end

    it 'sends the email to owners and masters' do
      expect(Notify).to receive(:prometheus_alert_fired_email).with(project.id, master.id, prometheus_alert).and_call_original
      expect(Notify).to receive(:prometheus_alert_fired_email).with(project.id, project.owner.id, prometheus_alert).and_call_original
      expect(Notify).not_to receive(:prometheus_alert_fired_email).with(project.id, developer.id, prometheus_alert)

      subject.prometheus_alerts_fired(prometheus_alert.project, [prometheus_alert])
    end

    it_behaves_like 'project emails are disabled' do
      before do
        allow_any_instance_of(::Gitlab::Alerting::Alert).to receive(:valid?).and_return(true)
      end

      let(:alert_params) { { 'labels' => { 'gitlab_alert_id' => 'unknown' } } }
      let(:notification_target)  { prometheus_alert.project }
      let(:notification_trigger) { subject.prometheus_alerts_fired(prometheus_alert.project, [alert_params]) }

      around do |example|
        perform_enqueued_jobs { example.run }
      end
    end
  end

  describe 'epics' do
    set(:group) { create(:group, :private) }
    set(:epic) { create(:epic, group: group) }

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    before do
      stub_licensed_features(epics: true)
      group.add_developer(epic.author)
    end

    context 'epic notes' do
      let(:note) { create(:note, project: nil, noteable: epic, note: '@mention referenced, @unsubscribed_mentioned and @outsider also') }

      before do
        build_group_members(group)

        @u_custom_off = create_user_with_notification(:custom, 'custom_off', group)
        create(:group_member, group: group, user: @u_custom_off)

        create(
          :note,
          project: nil,
          noteable: epic,
          author: @u_custom_off,
          note: 'i think @subscribed_participant should see this'
        )

        update_custom_notification(:new_note, @u_guest_custom, resource: group)
        update_custom_notification(:new_note, @u_custom_global)
        add_users_with_subscription(group, epic)
      end

      describe '#new_note' do
        it do
          reset_delivered_emails!

          expect(SentNotification).to receive(:record).with(epic, any_args).exactly(9).times

          subject.new_note(note)

          should_email(@u_watcher)
          should_email(note.noteable.author)
          should_email(@u_custom_global)
          should_email(@u_mentioned)
          should_email(@subscriber)
          should_email(@watcher_and_subscriber)
          should_email(@subscribed_participant)
          should_email(@u_custom_off)
          should_email(@unsubscribed_mentioned)
          should_not_email(@u_guest_custom)
          should_not_email(@u_guest_watcher)
          should_not_email(note.author)
          should_not_email(@u_participating)
          should_not_email(@u_disabled)
          should_not_email(@unsubscriber)
          should_not_email(@u_outsider_mentioned)
          should_not_email(@u_lazy_participant)

          expect(find_email_for(@u_mentioned)).to have_header('X-GitLab-NotificationReason', 'mentioned')
          expect(find_email_for(@u_custom_global)).to have_header('X-GitLab-NotificationReason', '')
        end

        it_behaves_like 'group emails are disabled' do
          let(:notification_target)  { epic.group }
          let(:notification_trigger) { subject.new_note(note) }
        end
      end
    end

    shared_examples 'epic notifications' do
      let(:watcher) { create(:user) }
      let(:participating) { create(:user) }
      let(:other_user) { create(:user) }

      before do
        create_global_setting_for(watcher, :watch)
        create_global_setting_for(participating, :participating)

        group.add_developer(watcher)
        group.add_developer(participating)
        group.add_developer(other_user)

        reset_delivered_emails!
      end

      it 'sends notification to watcher when no user participates' do
        execute

        should_email(watcher)
        should_not_email(participating)
        should_not_email(other_user)
      end

      it 'sends notification to watcher and a participator' do
        epic.subscriptions.create(user: participating, subscribed: true)

        execute

        should_email(watcher)
        should_email(participating)
        should_not_email(other_user)
      end

      it_behaves_like 'group emails are disabled' do
        let(:notification_target)  { epic.group }
        let(:notification_trigger) { execute }
      end
    end

    context 'close epic' do
      let(:execute) { subject.close_epic(epic, epic.author) }

      include_examples 'epic notifications'
    end

    context 'reopen epic' do
      let(:execute) { subject.reopen_epic(epic, epic.author) }

      include_examples 'epic notifications'
    end

    context 'new epic' do
      let(:execute) { subject.new_epic(epic) }

      include_examples 'epic notifications'
    end
  end

  def build_group_members(group)
    @u_watcher               = create_global_setting_for(create(:user), :watch)
    @u_participating         = create_global_setting_for(create(:user), :participating)
    @u_participant_mentioned = create_global_setting_for(create(:user, username: 'participant'), :participating)
    @u_disabled              = create_global_setting_for(create(:user), :disabled)
    @u_mentioned             = create_global_setting_for(create(:user, username: 'mention'), :mention)
    @u_committer             = create(:user, username: 'committer')
    @u_not_mentioned         = create_global_setting_for(create(:user, username: 'regular'), :participating)
    @u_outsider_mentioned    = create(:user, username: 'outsider')
    @u_custom_global         = create_global_setting_for(create(:user, username: 'custom_global'), :custom)

    # User to be participant by default
    # This user does not contain any record in notification settings table
    # It should be treated with a :participating notification_level
    @u_lazy_participant      = create(:user, username: 'lazy-participant')

    @u_guest_watcher = create_user_with_notification(:watch, 'guest_watching', group)
    @u_guest_custom = create_user_with_notification(:custom, 'guest_custom', group)

    create(:group_member, group: group, user: @u_watcher)
    create(:group_member, group: group, user: @u_participating)
    create(:group_member, group: group, user: @u_participant_mentioned)
    create(:group_member, group: group, user: @u_disabled)
    create(:group_member, group: group, user: @u_mentioned)
    create(:group_member, group: group, user: @u_committer)
    create(:group_member, group: group, user: @u_not_mentioned)
    create(:group_member, group: group, user: @u_lazy_participant)
    create(:group_member, group: group, user: @u_custom_global)
  end

  def add_users_with_subscription(group, issuable)
    @subscriber = create :user
    @unsubscriber = create :user
    @unsubscribed_mentioned = create :user, username: 'unsubscribed_mentioned'
    @subscribed_participant = create_global_setting_for(create(:user, username: 'subscribed_participant'), :participating)
    @watcher_and_subscriber = create_global_setting_for(create(:user), :watch)

    create(:group_member, group: group, user: @subscribed_participant)
    create(:group_member, group: group, user: @subscriber)
    create(:group_member, group: group, user: @unsubscriber)
    create(:group_member, group: group, user: @watcher_and_subscriber)
    create(:group_member, group: group, user: @unsubscribed_mentioned)

    issuable.subscriptions.create(user: @unsubscribed_mentioned, subscribed: false)
    issuable.subscriptions.create(user: @subscriber, subscribed: true)
    issuable.subscriptions.create(user: @subscribed_participant, subscribed: true)
    issuable.subscriptions.create(user: @unsubscriber, subscribed: false)
    # Make the watcher a subscriber to detect dupes
    issuable.subscriptions.create(user: @watcher_and_subscriber, subscribed: true)
  end

  context 'Merge Requests' do
    let(:notification) { NotificationService.new }
    let(:assignee) { create(:user) }
    let(:assignee2) { create(:user) }
    let(:group) { create(:group) }
    let(:project) { create(:project, :public, :repository, namespace: group) }
    let(:another_project) { create(:project, :public, namespace: group) }
    let(:merge_request) { create :merge_request, source_project: project, assignees: [assignee, assignee2], description: 'cc @participant' }

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    before do
      project.add_maintainer(merge_request.author)
      merge_request.assignees.each { |assignee| project.add_maintainer(assignee) }
      build_team(merge_request.target_project)
      add_users_with_subscription(merge_request.target_project, merge_request)
      update_custom_notification(:new_merge_request, @u_guest_custom, resource: project)
      update_custom_notification(:new_merge_request, @u_custom_global)
      reset_delivered_emails!
    end

    describe '#new_merge_request' do
      it 'emails all assignees' do
        notification.new_merge_request(merge_request, assignee)

        merge_request.assignees.each { |assignee| should_email(assignee) }
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.new_merge_request(merge_request, assignee) }
      end

      context 'when the target project has approvers set' do
        let(:project_approvers) { create_list(:user, 3) }
        let!(:rule) { create(:approval_project_rule, project: project, users: project_approvers, approvals_required: 1 )}

        before do
          reset_delivered_emails!
        end

        it 'emails the approvers' do
          notification.new_merge_request(merge_request, @u_disabled)

          project_approvers.each { |approver| should_email(approver) }
        end

        it 'does not email the approvers when approval is not necessary' do
          project.approval_rules.update_all(approvals_required: 0)
          notification.new_merge_request(merge_request, @u_disabled)

          project_approvers.each { |approver| should_not_email(approver) }
        end

        it_behaves_like 'project emails are disabled' do
          let(:notification_target)  { merge_request }
          let(:notification_trigger) { notification.new_merge_request(merge_request, @u_disabled) }
        end

        context 'when the merge request has approvers set' do
          let(:mr_approvers) { create_list(:user, 3) }
          let!(:mr_rule) { create(:approval_merge_request_rule, merge_request: merge_request, users: mr_approvers, approvals_required: 1 )}

          before do
            reset_delivered_emails!
          end

          it 'emails the MR approvers' do
            notification.new_merge_request(merge_request, @u_disabled)

            mr_approvers.each { |approver| should_email(approver) }
          end

          it 'does not email approvers set on the project who are not approvers of this MR' do
            notification.new_merge_request(merge_request, @u_disabled)

            project_approvers.each { |approver| should_not_email(approver) }
          end

          it_behaves_like 'project emails are disabled' do
            let(:notification_target)  { merge_request }
            let(:notification_trigger) { notification.new_merge_request(merge_request, @u_disabled) }
          end
        end
      end
    end

    def build_team(project)
      @u_watcher               = create_global_setting_for(create(:user), :watch)
      @u_participating         = create_global_setting_for(create(:user), :participating)
      @u_participant_mentioned = create_global_setting_for(create(:user, username: 'participant'), :participating)
      @u_disabled              = create_global_setting_for(create(:user), :disabled)
      @u_mentioned             = create_global_setting_for(create(:user, username: 'mention'), :mention)
      @u_committer             = create(:user, username: 'committer')
      @u_not_mentioned         = create_global_setting_for(create(:user, username: 'regular'), :participating)
      @u_outsider_mentioned    = create(:user, username: 'outsider')
      @u_custom_global         = create_global_setting_for(create(:user, username: 'custom_global'), :custom)

      # User to be participant by default
      # This user does not contain any record in notification settings table
      # It should be treated with a :participating notification_level
      @u_lazy_participant      = create(:user, username: 'lazy-participant')

      @u_guest_watcher = create_user_with_notification(:watch, 'guest_watching')
      @u_guest_custom = create_user_with_notification(:custom, 'guest_custom')

      [@u_watcher, @u_participating, @u_participant_mentioned, @u_disabled, @u_mentioned, @u_committer, @u_not_mentioned, @u_lazy_participant, @u_custom_global].each do |user|
        project.add_maintainer(user)
      end
    end

    def add_users_with_subscription(project, issuable)
      @subscriber = create :user
      @unsubscriber = create :user
      @unsubscribed_mentioned = create :user, username: 'unsubscribed_mentioned'
      @subscribed_participant = create_global_setting_for(create(:user, username: 'subscribed_participant'), :participating)
      @watcher_and_subscriber = create_global_setting_for(create(:user), :watch)

      [@subscribed_participant, @subscriber, @unsubscriber, @watcher_and_subscriber, @unsubscribed_mentioned].each do |user|
        project.add_maintainer(user)
      end

      issuable.subscriptions.create(user: @unsubscribed_mentioned, project: project, subscribed: false)
      issuable.subscriptions.create(user: @subscriber, project: project, subscribed: true)
      issuable.subscriptions.create(user: @subscribed_participant, project: project, subscribed: true)
      issuable.subscriptions.create(user: @unsubscriber, project: project, subscribed: false)
      # Make the watcher a subscriber to detect dupes
      issuable.subscriptions.create(user: @watcher_and_subscriber, project: project, subscribed: true)
    end
  end
end
