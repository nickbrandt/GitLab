# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::TransferService, '#execute' do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:new_group) { create(:group, :public) }
  let(:transfer_service) { described_class.new(group, user) }

  before do
    stub_licensed_features(packages: true)
    group.add_owner(user)
    new_group&.add_owner(user)
  end

  context 'with an npm package' do
    before do
      create(:npm_package, project: project)
    end

    shared_examples 'transfer not allowed' do
      it 'does not allow transfer when there is a root namespace change' do
        transfer_service.execute(new_group)

        expect(transfer_service.error).to eq('Transfer failed: Group contains projects with NPM packages.')
      end
    end

    it_behaves_like 'transfer not allowed'

    context 'with a project within subgroup' do
      let(:root_group) { create(:group) }
      let(:group) { create(:group, parent: root_group) }

      before do
        root_group.add_owner(user)
      end

      it_behaves_like 'transfer not allowed'

      context 'without a root namespace change' do
        let(:new_group) { create(:group, parent: root_group) }

        it 'allows transfer' do
          transfer_service.execute(new_group)

          expect(transfer_service.error).not_to be
          expect(group.parent).to eq(new_group)
        end
      end

      context 'when transferring a group into a root group' do
        let(:new_group) { nil }

        it_behaves_like 'transfer not allowed'
      end
    end
  end

  context 'without an npm package' do
    context 'when transferring a group into a root group' do
      let(:group) { create(:group, parent: create(:group)) }

      it 'allows transfer' do
        transfer_service.execute(nil)

        expect(transfer_service.error).not_to be
        expect(group.parent).to be_nil
      end
    end
  end

  context 'when visibility changes' do
    let(:new_group) { create(:group, :private) }

    before do
      stub_ee_application_setting(elasticsearch_indexing: true)
    end

    it 'reindexes projects', :elastic do
      project1 = create(:project, :repository, :public, namespace: group)
      project2 = create(:project, :repository, :public, namespace: group)
      project3 = create(:project, :repository, :private, namespace: group)

      expect(ElasticIndexerWorker).to receive(:perform_async)
        .with(:update, "Project", project1.id, project1.es_id)
      expect(ElasticIndexerWorker).to receive(:perform_async)
        .with(:update, "Project", project2.id, project2.es_id)
      expect(ElasticIndexerWorker).not_to receive(:perform_async)
        .with(:update, "Project", project3.id, project3.es_id)

      transfer_service.execute(new_group)

      expect(transfer_service.error).not_to be
      expect(group.parent).to eq(new_group)
    end
  end

  context 'with epics' do
    context 'when epics feature is disabled' do
      it 'transfers a group successfully' do
        transfer_service.execute(new_group)

        expect(group.parent).to eq(new_group)
      end
    end

    context 'when epics feature is enabled' do
      let(:root_group) { create(:group) }
      let(:subgroup_group_level_1) { create(:group, parent: root_group) }
      let(:subgroup_group_level_2) { create(:group, parent: subgroup_group_level_1) }
      let(:subgroup_group_level_3) { create(:group, parent: subgroup_group_level_2) }

      let!(:root_epic) { create(:epic, group: root_group) }
      let!(:level_1_epic_1) { create(:epic, group: subgroup_group_level_1, parent: root_epic) }
      let!(:level_1_epic_2) { create(:epic, group: subgroup_group_level_1, parent: level_1_epic_1) }
      let!(:level_2_epic_1) { create(:epic, group: subgroup_group_level_2, parent: root_epic) }
      let!(:level_2_epic_2) { create(:epic, group: subgroup_group_level_2, parent: level_1_epic_1) }
      let!(:level_2_subepic) { create(:epic, group: subgroup_group_level_2, parent: level_2_epic_2) }
      let!(:level_3_epic) { create(:epic, group: subgroup_group_level_3, parent: level_2_epic_2) }

      before do
        root_group.add_owner(user)

        stub_licensed_features(epics: true)
      end

      context 'when group is moved completely out of the main group' do
        let(:group) { subgroup_group_level_1 }

        before do
          transfer_service.execute(new_group)
        end

        it 'keeps relations between epics in the group structure' do
          expect(level_1_epic_2.reload.parent).to eq(level_1_epic_1)
          expect(level_2_epic_2.reload.parent).to eq(level_1_epic_1)
          expect(level_2_subepic.reload.parent).to eq(level_2_epic_2)
          expect(level_3_epic.reload.parent).to eq(level_2_epic_2)
        end

        it 'removes relations to epics of the old parent group' do
          expect(level_1_epic_1.reload.parent).to be_nil
          expect(level_2_epic_1.reload.parent).to be_nil
        end
      end

      context 'when group is moved some levels up' do
        let(:group) { subgroup_group_level_2 }

        before do
          transfer_service.execute(root_group)
        end

        it 'keeps relations between epics in the group structure' do
          expect(level_1_epic_1.reload.parent).to eq(root_epic)
          expect(level_1_epic_2.reload.parent).to eq(level_1_epic_1)
          expect(level_2_epic_1.reload.parent).to eq(root_epic)
          expect(level_2_subepic.reload.parent).to eq(level_2_epic_2)
          expect(level_3_epic.reload.parent).to eq(level_2_epic_2)
        end

        it 'removes relations to epics of the old parent group' do
          expect(level_2_epic_2.reload.parent).to be_nil
        end
      end
    end
  end
end
