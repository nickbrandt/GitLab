# frozen_string_literal: true

require 'spec_helper'

describe Projects::TransferService do
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

    before do
      stub_licensed_features(packages: true)
    end

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

  describe 'transferring a design repository' do
    def design_repository
      project.design_repository
    end

    it 'does not create a design repository' do
      expect(subject.execute(group)).to be true

      project.clear_memoization(:design_repository)

      expect(design_repository.exists?).to be false
    end

    describe 'when the project has a design repository' do
      let(:project_repo_path) { "#{project.path}#{::Gitlab::GlRepository::DESIGN.path_suffix}" }
      let(:old_full_path) { "#{user.namespace.full_path}/#{project_repo_path}" }
      let(:new_full_path) { "#{group.full_path}/#{project_repo_path}" }

      context 'with legacy storage' do
        let(:project) { create(:project, :repository, :legacy_storage, :design_repo, namespace: user.namespace) }

        it 'moves the repository' do
          expect(subject.execute(group)).to be true

          project.clear_memoization(:design_repository)

          expect(design_repository).to have_attributes(
            disk_path: new_full_path,
            full_path: new_full_path
          )
        end

        it 'does not move the repository when an error occurs', :aggregate_failures do
          allow(subject).to receive(:execute_system_hooks).and_raise('foo')
          expect { subject.execute(group) }.to raise_error('foo')

          project.clear_memoization(:design_repository)

          expect(design_repository).to have_attributes(
            disk_path: old_full_path,
            full_path: old_full_path
          )
        end
      end

      context 'with hashed storage' do
        let(:project) { create(:project, :repository, namespace: user.namespace) }

        it 'does not move the repository' do
          old_disk_path = design_repository.disk_path

          expect(subject.execute(group)).to be true

          project.clear_memoization(:design_repository)

          expect(design_repository).to have_attributes(
            disk_path: old_disk_path,
            full_path: new_full_path
          )
        end

        it 'does not move the repository when an error occurs' do
          old_disk_path = design_repository.disk_path

          allow(subject).to receive(:execute_system_hooks).and_raise('foo')
          expect { subject.execute(group) }.to raise_error('foo')

          project.clear_memoization(:design_repository)

          expect(design_repository).to have_attributes(
            disk_path: old_disk_path,
            full_path: old_full_path
          )
        end
      end
    end
  end
end
