# frozen_string_literal: true

require 'spec_helper'

describe GroupsWithTemplatesFinder do
  let(:group_1) { create(:group, name: 'group-1') }
  let(:group_2) { create(:group, name: 'group-2') }
  let(:group_3) { create(:group, name: 'group-3') }
  let!(:group_4) { create(:group, name: 'group-4') }

  let!(:subgroup_1) { create(:group, parent: group_1, name: 'subgroup-1') }
  let!(:subgroup_2) { create(:group, parent: group_2, name: 'subgroup-2') }
  let!(:subgroup_3) { create(:group, parent: group_3, name: 'subgroup-3') }

  before do
    group_1.update!(custom_project_templates_group_id: subgroup_1.id)
    group_2.update!(custom_project_templates_group_id: subgroup_2.id)
    group_3.update!(custom_project_templates_group_id: subgroup_3.id)
    create(:project, namespace: subgroup_1)
    create(:project, namespace: subgroup_2)
    create(:project, namespace: subgroup_3)
    create(:gitlab_subscription, :gold, namespace: group_1)
    create(:gitlab_subscription, :silver, namespace: group_2)
  end

  describe 'without group id' do
    it 'returns all groups' do
      expect(described_class.new.execute).to contain_exactly(group_1, group_2, group_3)
    end

    context 'when namespace checked' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?) { true }
      end

      it 'returns all groups before cut-off date' do
        Timecop.freeze(described_class::CUT_OFF_DATE - 1.day) do
          expect(described_class.new.execute).to contain_exactly(group_1, group_2, group_3)
        end
      end

      it 'returns groups on gold/silver plan after cut-off date' do
        Timecop.freeze(described_class::CUT_OFF_DATE + 1.day) do
          expect(described_class.new.execute).to contain_exactly(group_1, group_2)
        end
      end
    end
  end

  describe 'with group id' do
    it 'returns given group with it descendants' do
      expect(described_class.new(group_1.id).execute).to contain_exactly(group_1)
    end

    context 'when namespace checked' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?) { true }
      end

      it 'returns given group with it descendants before cut-off date' do
        Timecop.freeze(described_class::CUT_OFF_DATE - 1.day) do
          expect(described_class.new(group_3.id).execute).to contain_exactly(group_3)
        end
      end

      it 'does not return the group after the cut-off date' do
        Timecop.freeze(described_class::CUT_OFF_DATE + 1.day) do
          expect(described_class.new(group_3.id).execute).to be_empty
        end
      end
    end
  end
end
