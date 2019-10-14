# frozen_string_literal: true

require 'spec_helper'

describe Groups::TransferService, '#execute' do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:new_group) { create(:group, :public) }
  let(:transfer_service) { described_class.new(group, user) }

  before do
    stub_licensed_features(packages: true)
    group.add_owner(user)
    new_group.add_owner(user)
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
    end
  end
end
