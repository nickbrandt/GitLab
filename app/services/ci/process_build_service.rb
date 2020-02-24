# frozen_string_literal: true

module Ci
  class ProcessBuildService < BaseService
    def execute(build, current_status)
      if should_run?(build, current_status)
        if build.schedulable?
          build.schedule
        elsif build.action?
          build.actionize
        else
          enqueue(build)
        end

        true
      else
        build.skip
        false
      end
    end

    private

    def enqueue(build)
      build.enqueue
    end

    def should_run?(build, current_status)
      case build.when
      when 'on_success', 'manual', 'delayed'
        %w[success].include?(current_status[:name]) || current_status[:is_ignored]
      when 'on_failure'
        %w[failed].include?(current_status[:name])
      when 'always'
        %w[success failed].include?(current_status[:name]) || current_status[:is_ignored]
      else
        false
      end
    end
  end
end

Ci::ProcessBuildService.prepend_if_ee('EE::Ci::ProcessBuildService')
