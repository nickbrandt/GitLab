# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesTransferWorker do
  describe '#perform' do
    RSpec.shared_examples 'moving a pages directory' do |parameter|
      let!(:pages_path_before) { project.pages_path }
      let(:config_path_before) { File.join(pages_path_before, 'config.json') }
      let(:pages_path_after) { project.reload.pages_path }
      let(:config_path_after) { File.join(pages_path_after, 'config.json') }

      before do
        FileUtils.mkdir_p(pages_path_before)
        FileUtils.touch(config_path_before)
      end

      after do
        FileUtils.remove_entry(pages_path_before, true)
        FileUtils.remove_entry(pages_path_after, true)
      end

      it 'calls Gitlab::PagesTransfer to move the directory' do
        expect_next_instance_of(Gitlab::PagesTransfer) do |service|
          expect(service).to receive(meth).with(*args).and_call_original
        end

        subject.perform(meth, args)

        expect(File.exist?(config_path_before)).to be(false)
        expect(File.exist?(config_path_after)).to be(true)
      end

      it 'raises an exception if the service fails to move the directory' do
        # Move the directory once, so it can't be moved again
        subject.perform(meth, args)

        expect { subject.perform(meth, args) }
          .to raise_error(described_class::TransferFailedError)
      end
    end

    describe 'when method is move_namespace' do
      # Can't use let_it_be because we change the path
      let(:group_1) { create(:group) }
      let(:group_2) { create(:group) }
      let(:subgroup) { create(:group, parent: group_1) }
      let(:project) { create(:project, group: subgroup) }
      let(:new_path) { "#{group_2.path}/#{subgroup.path}" }
      let(:meth) { 'move_namespace' }

      # Store the path before we change it
      let!(:args) { [project.path, subgroup.full_path, new_path] }

      before do
        # We need to skip hooks, otherwise the directory will be moved
        # via an ActiveRecord callback
        subgroup.update_columns(parent_id: group_2.id)
        subgroup.route.update!(path: new_path)
      end

      include_examples 'moving a pages directory'
    end

    describe 'when method is move_project' do
      # Can't use let_it_be because we change the path
      let(:group_1) { create(:group) }
      let(:group_2) { create(:group) }
      let(:project) { create(:project, group: group_1) }
      let(:new_path) { group_2.path }
      let(:meth) { 'move_project' }
      let(:args) { [project.path, group_1.full_path, group_2.full_path] }

      include_examples 'moving a pages directory' do
        before do
          project.update!(group: group_2)
        end
      end
    end

    describe 'when method is rename_project' do
      # Can't use let_it_be because we change the path
      let(:project) { create(:project) }
      let(:new_path) { project.path.succ }
      let(:meth) { 'rename_project' }

      # Store the path before we change it
      let!(:args) { [project.path, new_path, project.namespace.full_path] }

      include_examples 'moving a pages directory' do
        before do
          project.update!(path: new_path)
        end
      end
    end

    describe 'when method is rename_namespace' do
      # Can't use let_it_be because we change the path
      let(:group) { create(:group) }
      let(:project) { create(:project, group: group) }
      let(:new_path) { project.namespace.full_path.succ }
      let(:meth) { 'rename_namespace' }

      # Store the path before we change it
      let!(:args) { [project.namespace.full_path, new_path] }

      before do
        # We need to skip hooks, otherwise the directory will be moved
        # via an ActiveRecord callback
        group.update_columns(path: new_path)
        group.route.update!(path: new_path)
      end

      include_examples 'moving a pages directory'
    end

    describe 'when method is not allowed' do
      it 'does nothing' do
        expect(Gitlab::PagesTransfer).not_to receive(:new)

        subject.perform('object_id', [])
      end
    end
  end
end
