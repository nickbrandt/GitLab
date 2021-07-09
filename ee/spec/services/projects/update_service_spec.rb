# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UpdateService, '#execute' do
  include EE::GeoHelpers

  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let(:project) { create(:project, :repository, creator: user, namespace: user.namespace) }

  context 'shared runners' do
    let(:opts) { { shared_runners_enabled: enabled } }
    let(:enabled) { true }

    before do
      create(:gitlab_subscription, namespace: user.namespace, hosted_plan: create(:free_plan))
      allow(::Gitlab).to receive(:com?).and_return(true)
    end

    context 'when shared runners are on' do
      let(:enabled) { false }

      before do
        project.update!(shared_runners_enabled: true)
      end

      it 'disables shared runners', :aggregate_failures do
        result = update_project(project, user, opts)

        expect(result).to eq(status: :success)
        expect(project).to have_attributes(opts)
      end

      context 'when user has valid credit card' do
        before do
          create(:credit_card_validation, user: user)
        end

        it 'disables shared runners', :aggregate_failures do
          result = update_project(project, user, opts)

          expect(result).to eq(status: :success)
          expect(project).to have_attributes(opts)
        end
      end
    end

    context 'when shared runners are off' do
      before do
        project.update!(shared_runners_enabled: false)
      end

      context 'when user has valid credit card' do
        before do
          create(:credit_card_validation, user: user)
        end

        it 'enables shared runners', :aggregate_failures do
          result = update_project(project, user, opts)

          expect(result).to eq(status: :success)
          expect(project).to have_attributes(opts)
        end
      end

      context 'when user does not have valid credit card' do
        it 'does not enable shared runners', :aggregate_failures do
          result = update_project(project, user, opts)

          project.reload

          expect(result).to eq(status: :error, message: 'Shared runners enabled cannot be enabled until a valid credit card is on file')
          expect(project.shared_runners_enabled).to eq(false)
        end
      end
    end
  end

  context 'repository mirror' do
    let(:opts) { { mirror: true, import_url: 'http://foo.com' } }

    before do
      stub_licensed_features(repository_mirrors: true)
    end

    it 'sets mirror attributes' do
      result = update_project(project, user, opts)

      expect(result).to eq(status: :success)
      expect(project).to have_attributes(opts)
      expect(project.mirror_user).to eq(user)
    end

    it 'does not touch mirror_user_id for non-mirror changes' do
      result = update_project(project, user, description: 'anything')

      expect(result).to eq(status: :success)
      expect(project.mirror_user).to be_nil
    end

    it 'forbids non-admins from setting mirror_user_id explicitly' do
      project.team.add_maintainer(admin)
      result = update_project(project, user, opts.merge(mirror_user_id: admin.id))

      expect(result).to eq(status: :error, message: 'Mirror user is invalid')
      expect(project.mirror_user).to be_nil
    end

    it 'allows admins to set mirror_user_id' do
      project.team.add_maintainer(admin)
      result = update_project(project, admin, opts.merge(mirror_user_id: user.id))

      expect(result).to eq(status: :success)
      expect(project.mirror_user).to eq(user)
    end

    it 'forces an import job' do
      expect_any_instance_of(EE::ProjectImportState).to receive(:force_import_job!).once

      update_project(project, user, opts)
    end
  end

  context 'audit events' do
    let(:audit_event_params) do
      {
        author_id: user.id,
        entity_id: project.id,
        entity_type: 'Project',
        details: {
          author_name: user.name,
          target_id: project.id,
          target_type: 'Project',
          target_details: project.full_path
        }
      }
    end

    describe '#name' do
      include_examples 'audit event logging' do
        let!(:old_name) { project.full_name }
        let(:operation) { update_project(project, user, name: 'foobar') }
        let(:fail_condition!) do
          allow_any_instance_of(Project).to receive(:update).and_return(false)
        end

        let(:attributes) do
          audit_event_params.tap do |param|
            param[:details].merge!(
              change: 'name',
              from: old_name,
              to: project.full_name
            )
          end
        end
      end
    end

    describe '#path' do
      include_examples 'audit event logging' do
        let(:operation) { update_project(project, user, path: 'foobar1') }
        let(:fail_condition!) do
          allow_any_instance_of(Project).to receive(:update).and_return(false)
        end

        let(:attributes) do
          audit_event_params.tap do |param|
            param[:details].merge!(
              change: 'path',
              from: project.old_path_with_namespace,
              to: project.full_path
            )
          end
        end
      end
    end

    describe '#default_branch' do
      include_examples 'audit event logging' do
        let(:operation) { update_project(project, user, default_branch: 'feature') }
        let(:fail_condition!) do
          allow_next_instance_of(Project) do |project|
            allow(project).to receive(:change_head).and_return(false)
          end
        end

        let(:attributes) do
          audit_event_params.tap do |param|
            param[:details].merge!(
              custom_message: "Default branch changed from master to feature"
            )
          end
        end
      end
    end

    describe '#visibility' do
      include_examples 'audit event logging' do
        let(:operation) do
          update_project(project, user, visibility_level: Gitlab::VisibilityLevel::INTERNAL)
        end

        let(:fail_condition!) do
          allow_any_instance_of(Project).to receive(:update).and_return(false)
        end

        let(:attributes) do
          audit_event_params.tap do |param|
            param[:details].merge!(
              change: 'visibility',
              from: 'Private',
              to: 'Internal'
            )
          end
        end
      end
    end
  end

  context 'triggering wiki Geo syncs', :geo do
    context 'on a Geo primary' do
      let_it_be(:primary)   { create(:geo_node, :primary) }
      let_it_be(:secondary) { create(:geo_node) }

      before do
        stub_current_geo_node(primary)
      end

      context 'when enabling a wiki' do
        it 'creates a RepositoryUpdatedEvent' do
          project.project_feature.update!(wiki_access_level: ProjectFeature::DISABLED)
          project.reload

          expect do
            result = update_project(project, user, project_feature_attributes: { wiki_access_level: ProjectFeature::ENABLED })
            expect(result).to eq({ status: :success })
          end.to change { Geo::RepositoryUpdatedEvent.count }.by(1)

          expect(project.wiki_enabled?).to be true
        end
      end

      context 'when we update project but not enabling a wiki' do
        context 'when the wiki is disabled' do
          it 'does not create a RepositoryUpdatedEvent' do
            project.project_feature.update!(wiki_access_level: ProjectFeature::DISABLED)

            expect do
              result = update_project(project, user, { name: 'test1' })
              expect(result).to eq({ status: :success })
            end.not_to change { Geo::RepositoryUpdatedEvent.count }

            expect(project.wiki_enabled?).to be false
          end
        end

        context 'when the wiki was already enabled' do
          it 'does not create a RepositoryUpdatedEvent' do
            project.project_feature.update!(wiki_access_level: ProjectFeature::ENABLED)

            expect do
              result = update_project(project, user, { name: 'test1' })
              expect(result).to eq({ status: :success })
            end.not_to change { Geo::RepositoryUpdatedEvent.count }

            expect(project.wiki_enabled?).to be true
          end
        end
      end
    end

    context 'not on a Geo node' do
      before do
        allow(::Gitlab::Geo).to receive(:current_node).and_return(nil)
      end

      it 'does not create a RepositoryUpdatedEvent when enabling a wiki' do
        project.project_feature.update!(wiki_access_level: ProjectFeature::DISABLED)
        project.reload

        expect do
          result = update_project(project, user, project_feature_attributes: { wiki_access_level: ProjectFeature::ENABLED })
          expect(result).to eq({ status: :success })
        end.not_to change { Geo::RepositoryUpdatedEvent.count }

        expect(project.wiki_enabled?).to be true
      end
    end
  end

  context 'repository_size_limit assignment as Bytes' do
    let(:admin_user) { create(:user, admin: true) }
    let(:project) { create(:project, repository_size_limit: 0) }

    context 'when param present' do
      let(:opts) { { repository_size_limit: '100' } }

      it 'converts from MB to Bytes' do
        update_project(project, admin_user, opts)

        expect(project.reload.repository_size_limit).to eql(100 * 1024 * 1024)
      end
    end

    context 'when param not present' do
      let(:opts) { { repository_size_limit: '' } }

      it 'assign nil value' do
        update_project(project, admin_user, opts)

        expect(project.reload.repository_size_limit).to be_nil
      end
    end
  end

  context 'when there are merge requests in merge train' do
    before do
      stub_licensed_features(merge_pipelines: true, merge_trains: true)
      project.update!(merge_pipelines_enabled: true)
    end

    let!(:first_merge_request) do
      create(:merge_request, :on_train, target_project: project, source_project: project)
    end

    let!(:second_merge_request) do
      create(:merge_request, :on_train, target_project: project, source_project: project, source_branch: 'feature-1')
    end

    context 'when merge pipelines option is disabled' do
      it 'drops all merge request in the train', :sidekiq_might_not_need_inline do
        expect do
          update_project(project, user, merge_pipelines_enabled: false)
        end.to change { MergeTrain.count }.from(2).to(0)
      end
    end

    context 'when merge pipelines option stays enabled' do
      it 'does not drop all merge request in the train' do
        expect do
          update_project(project, user, merge_pipelines_enabled: true)
        end.not_to change { MergeTrain.count }
      end
    end
  end

  context 'custom compliance frameworks' do
    let(:framework) { create(:compliance_framework, namespace: project.namespace) }
    let(:opts) { { compliance_framework_setting_attributes: { framework: framework.id } } }

    context 'when current_user has :admin_compliance_framework ability' do
      before do
        stub_licensed_features(compliance_framework: true)
      end

      it 'updates the framework' do
        expect { update_project(project, user, opts) }.to change {
          project
            .reload
            .compliance_management_framework
        }.from(nil).to(framework)
      end

      it 'unassigns a framework from a project' do
        project.compliance_management_framework = framework

        expect { update_project(project, user, { compliance_framework_setting_attributes: { framework: nil } }) }.to change {
          project
            .reload
            .compliance_management_framework
        }.from(framework).to(nil)
      end
    end

    context 'when current_user does not have :admin_compliance_framework ability' do
      before do
        stub_licensed_features(compliance_framework: false)
      end

      it 'does not set a framework' do
        update_project(project, user, opts)

        expect(project.reload.compliance_management_framework).not_to be_present
      end
    end
  end

  it 'returns an error result when record cannot be updated' do
    admin = create(:admin)

    result = update_project(project, admin, { name: 'foo&bar' })

    expect(result).to eq({ status: :error, message: "Name can contain only letters, digits, emojis, '_', '.', dash, space. It must start with letter, digit, emoji or '_'." })
  end

  it 'calls remove_import_data if mirror was disabled in previous change' do
    update_project(project, user, { mirror: false })

    expect(project.import_data).to be_nil
    expect(project).not_to be_mirror
  end

  def update_project(project, user, opts)
    Projects::UpdateService.new(project, user, opts).execute
  end
end
