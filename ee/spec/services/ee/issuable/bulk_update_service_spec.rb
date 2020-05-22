# frozen_string_literal: true

require 'spec_helper'

describe Issuable::BulkUpdateService do
  let_it_be(:user)  { create(:user) }
  let_it_be(:group) { create(:group) }

  context 'with issues' do
    subject { described_class.new(parent, user, params).execute('issue') }

    let_it_be(:project1) { create(:project, :repository, group: group) }
    let_it_be(:project2) { create(:project, :repository, group: group) }
    let_it_be(:issue1) { create(:issue, project: project1) }
    let_it_be(:issue2) { create(:issue, project: project2) }
    let_it_be(:issue3) { create(:issue, project: project1) }

    describe 'updating health status' do
      shared_examples 'updates health status' do
        it 'succeeds and returns the correct number of issues updated' do
          expect(subject[:success]).to be_truthy
          expect(subject[:count]).to eq(2)
          issues.each do |issue|
            expect(issue.reload.health_status).to eq("on_track")
          end
        end
      end

      context 'when issuable_health_status feature is disabled' do
        let_it_be(:parent) { project1 }
        let_it_be(:issues) { [issue1, issue2] }
        let_it_be(:params) { { issuable_ids: issues.map(&:id), health_status: 1 } }

        before do
          group.add_reporter(user)
          stub_licensed_features(issuable_health_status: false)
        end

        it 'does not update health status' do
          issues.each do |issue|
            expect { subject }.not_to change { issue.health_status }
          end
        end
      end

      context 'when issuable_health_status feature is enabled' do
        let(:issues) { [issue1, issue3] }
        let(:params) { { issuable_ids: issues.map(&:id), health_status: 1 } }

        before do
          group.add_reporter(user)
          stub_licensed_features(issuable_health_status: true)
        end

        context 'with issuables at the project level' do
          let(:parent) { project1 }

          it_behaves_like 'updates health status'
        end

        context 'with issuables at the group level' do
          let(:parent) { group }
          let(:issues) { [issue1, issue2] }

          it_behaves_like 'updates health status'
        end
      end
    end
  end

  context 'with epics' do
    subject { described_class.new(group, user, params).execute('epic') }

    let(:epic1) { create(:epic, group: group, labels: [label1]) }
    let(:epic2) { create(:epic, group: group, labels: [label1]) }

    let_it_be(:label1) { create(:group_label, group: group) }

    before do
      group.add_reporter(user)
      stub_licensed_features(epics: true)
    end

    describe 'updating labels' do
      let_it_be(:label2) { create(:group_label, group: group, title: 'Bug') }
      let_it_be(:label3) { create(:group_label, group: group, title: 'suggestion') }

      let(:issuables) { [epic1, epic2] }
      let(:params) do
        {
          issuable_ids: issuables.map(&:id).join(','),
          add_label_ids: [label2.id, label3.id],
          remove_label_ids: [label1.id]
        }
      end

      context 'when epics are enabled' do
        it 'updates epic labels' do
          expect(subject[:success]).to be_truthy
          expect(subject[:count]).to eq(issuables.count)

          issuables.each do |issuable|
            expect(issuable.reload.labels).to eq([label2, label3])
          end
        end
      end

      context 'when epics are disabled' do
        before do
          stub_licensed_features(epics: false)
        end

        it 'does not update labels' do
          issuables.each do |issuable|
            expect { subject }.not_to change { issuable.labels }
          end
        end
      end

      context 'when issuable_ids contain external epics' do
        let(:epic3) { create(:epic, group: create(:group, parent: group), labels: [label1]) }
        let(:outer_epic) { create(:epic, labels: [label1]) }
        let(:params) { { issuable_ids: [epic1.id, epic3.id, outer_epic.id], add_label_ids: [label3.id] } }

        it 'updates epics that belong to the parent group or descendants' do
          expect(subject[:success]).to be_truthy
          expect(subject[:count]).to eq(2)

          expect(epic1.reload.labels).to eq([label1, label3])
          expect(epic3.reload.labels).to eq([label1, label3])
          expect(outer_epic.reload.labels).to eq([label1])
        end
      end
    end
  end

  def bulk_update(parent, issuables, extra_params = {})
    bulk_update_params = extra_params
      .reverse_merge(issuable_ids: Array(issuables).map(&:id).join(','))

    type = Array(issuables).first.model_name.param_key
    Issuable::BulkUpdateService.new(parent, user, bulk_update_params).execute(type)
  end
end
