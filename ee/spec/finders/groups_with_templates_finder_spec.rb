# frozen_string_literal: true

require 'spec_helper'

describe GroupsWithTemplatesFinder do
  set(:group_1) { create(:group, name: 'group-1') }
  set(:group_2) { create(:group, name: 'group-2') }
  set(:group_3) { create(:group, name: 'group-3') }
  set(:group_4) { create(:group, name: 'group-4') }

  set(:subgroup_1) { create(:group, parent: group_1, name: 'subgroup-1') }
  set(:subgroup_2) { create(:group, parent: group_2, name: 'subgroup-2') }
  set(:subgroup_3) { create(:group, parent: group_3, name: 'subgroup-3') }

  set(:subgroup_4) { create(:group, parent: group_1, name: 'subgroup-4') }
  set(:subgroup_5) { create(:group, parent: subgroup_4, name: 'subgroup-5') }

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

      context 'with subgroup with template' do
        before do
          subgroup_4.update!(custom_project_templates_group_id: subgroup_5.id)
          create(:project, namespace: subgroup_5)
        end

        it 'returns groups on gold/silver plan after cut-off date' do
          Timecop.freeze(described_class::CUT_OFF_DATE + 1.day) do
            expect(described_class.new.execute).to contain_exactly(group_1, group_2, subgroup_4)
          end
        end
      end
    end
  end

  describe 'with group id' do
    it 'returns given group with it descendants' do
      expect(described_class.new(group_1.id).execute).to contain_exactly(group_1)
    end

    context 'with subgroup with template' do
      before do
        subgroup_4.update!(custom_project_templates_group_id: subgroup_5.id)
        create(:project, namespace: subgroup_5)
      end

      it 'returns only chosen group' do
        expect(described_class.new(group_1.id).execute).to contain_exactly(group_1)
      end
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

      context 'with subgroup with template' do
        before do
          subgroup_4.update!(custom_project_templates_group_id: subgroup_5.id)
          create(:project, namespace: subgroup_5)
        end

        it 'returns only chosen group' do
          Timecop.freeze(described_class::CUT_OFF_DATE + 1.day) do
            expect(described_class.new(group_1.id).execute).to contain_exactly(group_1)
          end
        end

        it 'returns only chosen subgroup' do
          Timecop.freeze(described_class::CUT_OFF_DATE + 1.day) do
            expect(described_class.new(subgroup_4.id).execute).to contain_exactly(group_1, subgroup_4)
          end
        end
      end
    end
  end
end
