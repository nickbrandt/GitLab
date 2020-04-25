# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TransferService do
  include EE::GeoHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let(:project) { create(:project, :repository, :legacy_storage, namespace: user.namespace) }

  subject { described_class.new(project, user) }

  before do
    group.add_owner(user)
  end

  context 'when running on a primary node' do
    let_it_be(:primary) { create(:geo_node, :primary) }
    let_it_be(:secondary) { create(:geo_node) }

    it 'logs an event to the Geo event log' do
      stub_current_geo_node(primary)

      expect { subject.execute(group) }.to change(Geo::RepositoryRenamedEvent, :count).by(1)
    end
  end

  context 'audit events' do
    include_examples 'audit event logging' do
      let(:operation) { subject.execute(group) }
      let(:fail_condition!) do
        expect_next_instance_of(Project) do |instance|
          expect(instance).to receive(:has_container_registry_tags?).and_return(true)
        end
      end
      let(:attributes) do
        {
           author_id: user.id,
           entity_id: project.id,
           entity_type: 'Project',
           details: {
             change: 'namespace',
             from: project.old_path_with_namespace,
             to: project.full_path,
             author_name: user.name,
             target_id: project.id,
             target_type: 'Project',
             target_details: project.full_path
           }
         }
      end
    end
  end

  context 'with npm packages' do
    let!(:package) { create(:npm_package, project: project) }

    context 'with a root namespace change' do
      it 'does not allow the transfer' do
        expect(subject.execute(group)).to be false
        expect(project.errors[:new_namespace]).to include("Root namespace can't be updated if project has NPM packages")
      end
    end

    context 'without a root namespace change' do
      let(:root) { create(:group) }
      let(:group) { create(:group, parent: root) }
      let(:other_group) { create(:group, parent: root) }
      let(:project) { create(:project, :repository, namespace: group) }

      before do
        other_group.add_owner(user)
      end

      it 'does allow the transfer' do
        expect(subject.execute(other_group)).to be true
        expect(project.errors[:new_namespace]).to be_empty
      end
    end
  end
end
