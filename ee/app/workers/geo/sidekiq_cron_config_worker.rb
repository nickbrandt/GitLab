# frozen_string_literal: true

module Geo
  class SidekiqCronConfigWorker
    include ApplicationWorker
    include CronjobQueue

    feature_category :geo_replication

    def perform
      Gitlab::Geo::CronManager.new.execute
    end
  end
end
