# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceStateEventFinder do
  let_it_be(:user) { create(:user) }
  let_it_be(:issue_project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: issue_project) }

  describe '#execute' do
    subject { described_class.new(user, issue).execute }

    it 'returns events accessible by user' do
      event = create(:resource_state_event, issue: issue)
      issue_project.add_guest(user)

      expect(subject).to eq [event]
    end

    it 'filters events if issues and MRs are private' do
      project = create(:project, :public, :issues_private, :merge_requests_private)
      issue = create(:issue, project: project)
      merge_request = create(:merge_request, source_project: project)

      create(:resource_state_event, issue: issue)
      create(:resource_state_event, merge_request: merge_request)

      expect(subject).to be_empty
    end

    it 'filters events not accessible by user' do
      project = create(:project, :private)
      issue = create(:issue, project: project)
      merge_request = create(:merge_request, source_project: project)

      create(:resource_state_event, issue: issue)
      create(:resource_state_event, merge_request: merge_request)

      expect(subject).to be_empty
    end
  end

  describe '#can_read_eventable?' do
    let(:project) { create(:project, :private) }

    subject { described_class.new(user, eventable).can_read_eventable? }

    context 'when eventable is a Issue' do
      let(:eventable) { create(:issue, project: project) }

      context 'when issue is readable' do
        before do
          project.add_developer(user)
        end

        it { is_expected.to be_truthy }
      end

      context 'when issue is not readable' do
        it { is_expected.to be_falsey }
      end
    end

    context 'when eventable is a MergeRequest' do
      let(:eventable) { create(:merge_request, source_project: project) }

      context 'when merge request is readable' do
        before do
          project.add_developer(user)
        end

        it { is_expected.to be_truthy }
      end

      context 'when merge request is not readable' do
        it { is_expected.to be_falsey }
      end
    end
  end
end
