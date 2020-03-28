# frozen_string_literal: true

require 'spec_helper'

describe Event do
  describe '#visible_to_user?' do
    let_it_be(:non_member) { create(:user) }
    let_it_be(:member) { create(:user) }
    let_it_be(:guest) { create(:user) }
    let_it_be(:reporter) { create(:user) }
    let_it_be(:author) { create(:author) }
    let_it_be(:admin) { create(:admin) }
    let_it_be(:project) { create(:project) }

    let(:users) { [non_member, member, reporter, guest, author, admin] }

    let(:epic) { create(:epic, group: group, author: author) }
    let(:note_on_epic) { create(:note, :on_epic, noteable: epic) }
    let(:event) { described_class.new(group: group, target: target, author: author) }

    before do
      stub_licensed_features(epics: true)

      project.add_developer(member)
      project.add_guest(guest)
      project.add_reporter(reporter)

      if defined?(group)
        group.add_developer(member)
        group.add_guest(guest)
      end
    end

    RSpec::Matchers.define :be_visible_to do |user|
      match do |event|
        event.visible_to_user?(user)
      end

      failure_message do |event|
        "expected that #{event} should be visible to #{user}"
      end

      failure_message_when_negated do |event|
        "expected that #{event} would not be visible to #{user}"
      end
    end

    RSpec::Matchers.define :have_access_to do |event|
      match do |user|
        event.visible_to_user?(user)
      end

      failure_message do |user|
        "expected that #{event} should be visible to #{user}"
      end

      failure_message_when_negated do |user|
        "expected that #{event} would not be visible to #{user}"
      end
    end

    shared_examples 'visible to group members only' do
      it 'is not visible to other users', :aggregate_failures do
        expect(event).not_to be_visible_to(non_member)
        expect(event).not_to be_visible_to(author)

        expect(event).to be_visible_to(member)
        expect(event).to be_visible_to(guest)
        expect(event).to be_visible_to(admin)
      end
    end

    shared_examples 'visible to everybody' do
      it 'is visible to other users', :aggregate_failures do
        expect(users).to all(have_access_to(event))
      end
    end

    context 'design event' do
      include DesignManagementTestHelpers

      before do
        enable_design_management
      end

      it_behaves_like 'visible to group members only' do
        let(:event) { create(:event, :for_design, project: project) }
      end

      context 'the event refers to a design on a confidential issue' do
        let(:project) { create(:project, :public) }
        let(:issue) { create(:issue, :confidential, project: project) }
        let(:note) { create(:note, :on_design, issue: issue) }
        let(:event) { create(:event, project: project, target: note) }

        let(:assignees) do
          create_list(:user, 3).each { |user| issue.assignees << user }
        end

        it 'visible to group reporters, the issue author, and assignees', :aggregate_failures do
          expect(event).not_to be_visible_to(non_member)
          expect(event).not_to be_visible_to(guest)

          expect(event).to be_visible_to(reporter)
          expect(event).to be_visible_to(member)
          expect(event).to be_visible_to(admin)
          expect(event).to be_visible_to(issue.author)

          expect(assignees).to all(have_access_to(event))
        end
      end
    end

    context 'epic event' do
      let(:target) { epic }

      context 'on public group' do
        let(:group) { create(:group, :public) }

        it_behaves_like 'visible to everybody'
      end

      context 'on private group' do
        let(:group) { create(:group, :private) }

        it_behaves_like 'visible to group members only'
      end
    end

    context 'epic note event' do
      let(:target) { note_on_epic }

      context 'on public group' do
        let(:group) { create(:group, :public) }

        it_behaves_like 'visible to everybody'
      end

      context 'private group' do
        let(:group) { create(:group, :private) }

        it_behaves_like 'visible to group members only'
      end
    end
  end
end
