# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::BulkUpdateService do
  let_it_be(:user)  { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project1) { create(:project, :repository, group: group) }
  let_it_be(:project2) { create(:project, :repository, group: group) }

  subject { described_class.new(parent, user, params).execute(type) }

  shared_examples 'updates issuables attribute' do |attribute|
    it 'succeeds and returns the correct number of issuables updated' do
      expect(subject[:success]).to be_truthy
      expect(subject[:count]).to eq(issuables.count)
      issuables.each do |issuable|
        expect(issuable.reload.send(attribute)).to eq(new_value)
      end
    end
  end

  shared_examples 'does not update issuables attribute' do |attribute|
    it 'does not update issuables' do
      issuables.each do |issuable|
        expect { subject }.not_to change { issuable.send(attribute) }
      end
    end
  end

  context 'with issues' do
    let_it_be(:type) { 'issue' }
    let_it_be(:parent) { group }
    let(:issue1) { create(:issue, project: project1, health_status: :at_risk, epic: epic) }
    let(:issue2) { create(:issue, project: project2, health_status: :at_risk, epic: epic) }
    let(:epic) { create(:epic, group: group) }
    let(:epic2) { create(:epic, group: group) }
    let(:issuables) { [issue1, issue2] }

    before do
      group.add_reporter(user)
    end

    context 'updating health status and epic' do
      let(:params) do
        {
          issuable_ids: issuables.map(&:id),
          health_status: :on_track,
          epic: epic2
        }
      end

      context 'when features are enabled' do
        before do
          stub_licensed_features(epics: true, issuable_health_status: true)
        end

        it 'succeeds and returns the correct number of issuables updated' do
          expect(subject[:success]).to be_truthy
          expect(subject[:count]).to eq(issuables.count)
          issuables.each do |issuable|
            issuable.reload
            expect(issuable.epic).to eq(epic2)
            expect(issuable.health_status).to eq('on_track')
          end
        end
      end

      context 'when features are disabled' do
        before do
          stub_licensed_features(epics: false, issuable_health_status: false)
        end

        it_behaves_like 'does not update issuables attribute', :health_status
        it_behaves_like 'does not update issuables attribute', :epic
      end

      context 'when user can not update issues' do
        before do
          group.add_guest(user)
        end

        it_behaves_like 'does not update issuables attribute', :health_status
        it_behaves_like 'does not update issuables attribute', :epic
      end

      context 'when user can not admin epic' do
        let(:epic3) { create(:epic, group: create(:group)) }
        let(:params) { { issuable_ids: issuables.map(&:id), epic: epic3 } }

        it_behaves_like 'does not update issuables attribute', :epic
      end
    end
  end

  context 'with epics' do
    let_it_be(:type) { 'epic' }
    let_it_be(:parent) { group }

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
        let(:new_value) { [label2, label3] }

        it_behaves_like 'updates issuables attribute', :labels
      end

      context 'when epics are disabled' do
        before do
          stub_licensed_features(epics: false)
        end

        it_behaves_like 'does not update issuables attribute', :labels
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
end
