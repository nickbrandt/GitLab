# frozen_string_literal: true

require 'spec_helper'

describe Issues::CreateService do
  let(:project) { create(:project) }
  let(:opts) do
    {
      title: 'Awesome issue',
      description: 'please fix',
      weight: 9
    }
  end

  context 'when current user cannot admin issues in the project' do
    let(:guest) { create(:user) }

    before do
      project.add_guest(guest)
    end

    it 'filters out params that cannot be set without the :admin_issue permission' do
      issue = described_class.new(project, guest, opts).execute

      expect(issue).to be_persisted
      expect(issue.weight).to be_nil
    end
  end

  context 'when current user can admin issues in the project' do
    let(:reporter) { create(:user) }

    before do
      stub_licensed_features(epics: true)
      project.add_reporter(reporter)
    end

    it 'sets permitted params correctly' do
      issue = described_class.new(project, reporter, opts).execute

      expect(issue).to be_persisted
      expect(issue.weight).to eq(9)
    end

    context 'when epics are enabled' do
      let(:group) { create(:group) }
      let(:project1) { create(:project, group: group) }
      let(:epic) { create(:epic, group: group, start_date_is_fixed: false, due_date_is_fixed: false) }

      before do
        stub_licensed_features(epics: true)
        group.add_reporter(reporter)
        project1.add_reporter(reporter)
      end

      context 'when using quick actions' do
        context 'with epic and milestone in commands only' do
          let(:milestone) { create(:milestone, group: group, start_date: Date.today, due_date: 7.days.from_now) }
          let(:opts) do
            {
              title: 'Awesome issue',
              description: %(/epic #{epic.to_reference}\n/milestone #{milestone.to_reference}")
            }
          end

          it 'sets epic and milestone to issuable and update epic start and due date' do
            issue = described_class.new(project1, reporter, opts).execute

            expect(issue.milestone).to eq(milestone)
            expect(issue.epic).to eq(epic)
            expect(epic.reload.start_date).to eq(milestone.start_date)
            expect(epic.due_date).to eq(milestone.due_date)
          end
        end
      end
    end
  end
end
