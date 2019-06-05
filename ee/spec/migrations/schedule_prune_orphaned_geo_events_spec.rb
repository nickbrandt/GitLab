# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('ee', 'db', 'post_migrate', '20180618193715_schedule_prune_orphaned_geo_events.rb')

describe SchedulePruneOrphanedGeoEvents, :migration, geo: false, schema: 20180615152524 do
  describe '#up', :postgresql do
    it 'does nothing if it is not running on PostgreSQL' do
      allow(Gitlab::Database).to receive(:postgresql?).and_return(false)

      expect(BackgroundMigrationWorker).not_to receive(:perform_async).with('PruneOrphanedGeoEvents')

      migrate!
    end

    it 'does nothing if the database is read-only' do
      allow(Gitlab::Database).to receive(:read_only?).and_return(true)

      expect(BackgroundMigrationWorker).not_to receive(:perform_async).with('PruneOrphanedGeoEvents')

      migrate!
    end

    it 'delegates work to Gitlab::BackgroundMigration::PruneOrphanedGeoEvents' do
      expect(BackgroundMigrationWorker).to receive(:perform_async).with('PruneOrphanedGeoEvents')

      migrate!
    end
  end
end
