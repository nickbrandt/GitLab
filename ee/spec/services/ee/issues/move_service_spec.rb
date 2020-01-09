# frozen_string_literal: true

require 'spec_helper'

describe Issues::MoveService do
  let(:user) { create(:user) }
  let(:old_project) { create(:project) }
  let(:new_project) { create(:project, group: create(:group)) }
  let(:old_issue) { create(:issue, project: old_project, author: user) }
  let(:move_service) { described_class.new(old_project, user) }

  before do
    old_project.add_reporter(user)
    new_project.add_reporter(user)
  end

  describe '#execute' do
    context 'group issue hooks' do
      let!(:hook) { create(:group_hook, group: new_project.group, issues_events: true) }

      it 'executes group issue hooks' do
        allow_any_instance_of(WebHookService).to receive(:execute)

        # Ideally, we'd test that `WebHookWorker.jobs.size` increased by 1,
        # but since the entire spec run takes place in a transaction, we never
        # actually get to the `after_commit` hook that queues these jobs.
        expect { move_service.execute(old_issue, new_project) }
          .not_to raise_error # Sidekiq::Worker::EnqueueFromTransactionError
      end
    end

    context 'resource weight events' do
      let!(:event1) { create(:resource_weight_event, issue: old_issue, weight: 1) }
      let!(:event2) { create(:resource_weight_event, issue: old_issue, weight: 42) }
      let!(:event3) { create(:resource_weight_event, issue: old_issue, weight: 5) }

      let!(:another_old_issue) { create(:issue, project: new_project, author: user) }
      let!(:event4) { create(:resource_weight_event, issue: another_old_issue, weight: 2) }

      it 'creates expected resource weight events' do
        new_issue = move_service.execute(old_issue, new_project)

        expect(new_issue.resource_weight_events.map(&:weight)).to contain_exactly(1, 42, 5)
      end
    end
  end

  describe '#rewrite_related_issues' do
    let(:user) { create(:user) }
    let(:admin) { create(:admin) }
    let(:authorized_project) { create(:project) }
    let(:authorized_project2) { create(:project) }
    let(:unauthorized_project) { create(:project) }

    let(:authorized_issue_b) { create(:issue, project: authorized_project) }
    let(:authorized_issue_c) { create(:issue, project: authorized_project2) }
    let(:authorized_issue_d) { create(:issue, project: authorized_project2) }
    let(:unauthorized_issue) { create(:issue, project: unauthorized_project) }

    let!(:issue_link_a) { create(:issue_link, source: old_issue, target: authorized_issue_b) }
    let!(:issue_link_b) { create(:issue_link, source: old_issue, target: unauthorized_issue) }
    let!(:issue_link_c) { create(:issue_link, source: old_issue, target: authorized_issue_c) }
    let!(:issue_link_d) { create(:issue_link, source: authorized_issue_d, target: old_issue) }

    before do
      stub_licensed_features(related_issues: true)
      authorized_project.add_developer(user)
      authorized_project2.add_developer(user)
    end

    context 'multiple related issues' do
      it 'moves all related issues and retains permissions' do
        new_issue = move_service.execute(old_issue, new_project)

        expect(new_issue.related_issues(admin))
          .to match_array([authorized_issue_b, authorized_issue_c, authorized_issue_d, unauthorized_issue])

        expect(new_issue.related_issues(user))
          .to match_array([authorized_issue_b, authorized_issue_c, authorized_issue_d])

        expect(authorized_issue_d.related_issues(user))
          .to match_array([new_issue])
      end
    end
  end

  describe '#rewrite_epic_issue' do
    context 'issue assigned to epic' do
      let!(:epic_issue) { create(:epic_issue, issue: old_issue) }

      before do
        stub_licensed_features(epics: true)
      end

      it 'updates epic issue reference' do
        epic_issue.epic.group.add_reporter(user)

        new_issue = move_service.execute(old_issue, new_project)

        expect(new_issue.epic_issue).to eq(epic_issue)
      end

      it 'ignores epic issue reference if user can not update the epic' do
        new_issue = move_service.execute(old_issue, new_project)

        expect(new_issue.epic_issue).to be_nil
      end
    end
  end
end
