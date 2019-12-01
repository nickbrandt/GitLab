# frozen_string_literal: true

module Ci
  class LegacyStagePresenter < Gitlab::View::Presenter::Delegated
    presents :legacy_stage

    def preloaded_statuses
      legacy_stage.statuses.tap do |statuses|
        # rubocop: disable CodeReuse/ActiveRecord
        ActiveRecord::Associations::Preloader.new.preload(preloadable_statuses(statuses), :tags)
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end

    private

    def preloadable_statuses(statuses)
      statuses.reject do |status|
        status.instance_of?(::GenericCommitStatus) || status.instance_of?(::Ci::Bridge)
      end
    end
  end
end
