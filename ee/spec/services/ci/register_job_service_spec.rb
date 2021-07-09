# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RegisterJobService, '#execute' do
  let_it_be_with_refind(:shared_runner) { create(:ci_runner, :instance) }

  let!(:project) { create(:project, shared_runners_enabled: true) }
  let!(:pipeline) { create(:ci_empty_pipeline, project: project) }
  let!(:pending_build) { create(:ci_build, :pending, :queued, pipeline: pipeline) }

  shared_examples 'namespace minutes quota' do
    context 'shared runners minutes limit' do
      subject { described_class.new(shared_runner).execute.build }

      shared_examples 'returns a build' do |runners_minutes_used|
        before do
          project.namespace.create_namespace_statistics(
            shared_runners_seconds: runners_minutes_used * 60)
        end

        context 'with traversal_ids enabled' do
          before do
            stub_feature_flags(sync_traversal_ids: true)
            stub_feature_flags(traversal_ids_for_quota_calculation: true)
          end

          it { is_expected.to be_kind_of(Ci::Build) }
        end

        context 'with traversal_ids disabled' do
          before do
            stub_feature_flags(traversal_ids_for_quota_calculation: false)
          end

          it { is_expected.to be_kind_of(Ci::Build) }
        end

        it 'when in disaster recovery it ignores quota and returns anyway' do
          stub_feature_flags(ci_queueing_disaster_recovery_disable_quota: true)

          is_expected.to be_kind_of(Ci::Build)
        end
      end

      shared_examples 'does not return a build' do |runners_minutes_used|
        before do
          project.namespace.create_namespace_statistics(
            shared_runners_seconds: runners_minutes_used * 60)
        end

        context 'with traversal_ids enabled' do
          before do
            stub_feature_flags(sync_traversal_ids: true)
            stub_feature_flags(traversal_ids_for_quota_calculation: true)
          end

          it { is_expected.to be_nil }
        end

        context 'with traversal_ids disabled' do
          before do
            stub_feature_flags(traversal_ids_for_quota_calculation: false)
          end

          it { is_expected.to be_nil }
        end

        it 'when in disaster recovery it ignores quota and returns anyway' do
          stub_feature_flags(ci_queueing_disaster_recovery_disable_quota: true)

          is_expected.to be_kind_of(Ci::Build)
        end
      end

      context 'when limit set at global level' do
        before do
          stub_application_setting(shared_runners_minutes: 10)
        end

        context 'and usage is below the limit' do
          it_behaves_like 'returns a build', 9
        end

        context 'and usage is above the limit' do
          it_behaves_like 'does not return a build', 11

          context 'and project is public' do
            context 'and public projects cost factor is 0 (default)' do
              before do
                project.update!(visibility_level: Project::PUBLIC)
              end

              it_behaves_like 'returns a build', 11
            end

            context 'and public projects cost factor is > 0' do
              before do
                project.update!(visibility_level: Project::PUBLIC)
                shared_runner.update!(public_projects_minutes_cost_factor: 1.1)
              end

              it_behaves_like 'does not return a build', 11
            end
          end
        end

        context 'and extra shared runners minutes purchased' do
          before do
            project.namespace.update!(extra_shared_runners_minutes_limit: 10)
          end

          context 'and usage is below the combined limit' do
            it_behaves_like 'returns a build', 19
          end

          context 'and usage is above the combined limit' do
            it_behaves_like 'does not return a build', 21
          end
        end
      end

      context 'when limit set at namespace level' do
        before do
          project.namespace.update!(shared_runners_minutes_limit: 5)
        end

        context 'and limit set to unlimited' do
          before do
            project.namespace.update!(shared_runners_minutes_limit: 0)
          end

          it_behaves_like 'returns a build', 10
        end

        context 'and usage is below the limit' do
          it_behaves_like 'returns a build', 4
        end

        context 'and usage is above the limit' do
          it_behaves_like 'does not return a build', 6
        end

        context 'and extra shared runners minutes purchased' do
          before do
            project.namespace.update!(extra_shared_runners_minutes_limit: 5)
          end

          context 'and usage is below the combined limit' do
            it_behaves_like 'returns a build', 9
          end

          context 'and usage is above the combined limit' do
            it_behaves_like 'does not return a build', 11
          end
        end
      end

      context 'when limit set at global and namespace level' do
        context 'and namespace limit lower than global limit' do
          before do
            stub_application_setting(shared_runners_minutes: 10)
            project.namespace.update!(shared_runners_minutes_limit: 5)
          end

          it_behaves_like 'does not return a build', 6
        end

        context 'and namespace limit higher than global limit' do
          before do
            stub_application_setting(shared_runners_minutes: 5)
            project.namespace.update!(shared_runners_minutes_limit: 10)
          end

          it_behaves_like 'returns a build', 6
        end
      end

      context 'when group is subgroup' do
        let!(:root_ancestor) { create(:group) }
        let!(:group) { create(:group, parent: root_ancestor) }
        let!(:project) { create :project, shared_runners_enabled: true, group: group }

        context 'and usage below the limit on root namespace' do
          before do
            root_ancestor.update!(shared_runners_minutes_limit: 10)
          end

          it_behaves_like 'returns a build', 9
        end

        context 'and usage above the limit on root namespace' do
          before do
            # limit is ignored on subnamespace
            group.update_columns(shared_runners_minutes_limit: 20)

            root_ancestor.update!(shared_runners_minutes_limit: 10)
            root_ancestor.create_namespace_statistics(
              shared_runners_seconds: 60 * 11)
          end

          it_behaves_like 'does not return a build', 11
        end
      end
    end

    context 'secrets' do
      let(:params) { { info: { features: { vault_secrets: true } } } }

      subject(:service) { described_class.new(shared_runner) }

      before do
        stub_licensed_features(ci_secrets_management: true)
      end

      context 'when build has secrets defined' do
        before do
          pending_build.update!(
            secrets: {
              DATABASE_PASSWORD: {
                vault: {
                  engine: { name: 'kv-v2', path: 'kv-v2' },
                  path: 'production/db',
                  field: 'password'
                }
              }
            }
          )
        end

        context 'when there is no Vault server provided' do
          it 'does not pick the build and drops the build' do
            result = service.execute(params).build

            aggregate_failures do
              expect(result).to be_nil
              expect(pending_build.reload).to be_failed
              expect(pending_build.failure_reason).to eq('secrets_provider_not_found')
              expect(pending_build).to be_secrets_provider_not_found
            end
          end
        end

        context 'when there is Vault server provided' do
          it 'picks the build' do
            create(:ci_variable, project: project, key: 'VAULT_SERVER_URL', value: 'https://vault.example.com')

            build = service.execute(params).build

            aggregate_failures do
              expect(build).not_to be_nil
              expect(build).to be_running
            end
          end
        end
      end

      context 'when build has no secrets defined' do
        it 'picks the build' do
          build = service.execute(params).build

          aggregate_failures do
            expect(build).not_to be_nil
            expect(build).to be_running
          end
        end
      end
    end
  end

  context 'when legacy queuing is being used' do
    before do
      stub_feature_flags(ci_pending_builds_queue_source: false)
    end

    include_examples 'namespace minutes quota'
  end

  context 'when new pending builds table is used' do
    before do
      stub_feature_flags(ci_pending_builds_queue_source: true)
    end

    include_examples 'namespace minutes quota'
  end
end
