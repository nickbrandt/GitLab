# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20191115121407_patch_prometheus_services_for_shared_cluster_applications.rb')

describe PatchPrometheusServicesForSharedClusterApplications, :migration, :sidekiq do
  let(:migration_class) { Gitlab::BackgroundMigration::ActivatePrometheusServicesForSharedClusterApplications }
  let(:migration_name) { migration_class.to_s.demodulize }

  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }


    let!(:project1) { projects.create!(name: 'gitlab', path: 'gitlab-ce', namespace_id: namespace.id) }
    let!(:project2) { projects.create!(name: 'gitlab', path: 'gitlab-ee', namespace_id: namespace.id) }

  it 'schedules a background migration' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(migration_name).to be_scheduled_delayed_migration(120.seconds, project1.id, project2.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq 1
      end
    end
  end
end
