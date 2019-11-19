# frozen_string_literal: true

require 'spec_helper'

describe Issuable::BulkUpdateService do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }

  context 'with epics' do
    subject { described_class.new(group, user, params).execute('epic') }

    let(:epic1) { create(:epic, group: group, labels: [label1]) }
    let(:epic2) { create(:epic, group: group, labels: [label1]) }
    let(:label1) { create(:group_label, group: group) }

    before do
      group.add_reporter(user)
      stub_licensed_features(epics: true)
    end

    describe 'updating labels' do
      let(:label2) { create(:group_label, group: group, title: 'Bug') }
      let(:label3) { create(:group_label, group: group, title: 'suggestion') }

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
          result = subject

          expect(result[:success]).to be_truthy
          expect(result[:count]).to eq(issuables.count)

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
        it 'updates epics that belong to the parent group or descendants' do
          epic3 = create(:epic, labels: [label1])
          epic4 = create(:epic, group: create(:group, parent: group), labels: [label1])
          params = { issuable_ids: [epic1.id, epic3.id, epic4.id], add_label_ids: [label3.id] }
          result = described_class.new(group, user, params).execute('epic')

          expect(result[:success]).to be_truthy
          expect(result[:count]).to eq(2)

          expect(epic1.reload.labels).to eq([label1, label3])
          expect(epic3.reload.labels).to eq([label1])
          expect(epic4.reload.labels).to eq([label1, label3])
        end
      end
    end
  end
end
