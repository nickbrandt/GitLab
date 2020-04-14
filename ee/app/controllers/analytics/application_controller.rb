# frozen_string_literal: true

module Analytics
  class ApplicationController < ApplicationController
    include RoutableActions

    layout 'analytics'

    private

    def self.check_feature_flag(flag, *args)
      before_action(*args) { render_404 unless Feature.enabled?(flag, default_enabled: Gitlab::Analytics.feature_enabled_by_default?(flag)) }
    end

    def self.increment_usage_counter(counter_klass, counter, *args)
      before_action(*args) { counter_klass.count(counter) }
    end

    def authorize_view_by_action!(action)
      return render_403 unless can?(current_user, action, @group || :global)
    end

    def check_feature_availability!(feature)
      return render_403 unless ::License.feature_available?(feature)
      return render_403 unless @group && @group.root_ancestor.feature_available?(feature)
    end

    def load_group
      return unless params['group_id']

      @group = find_routable!(Group, params['group_id'])
    end

    def load_project
      return unless @group && params['project_id']

      @project = find_routable!(@group.projects, params['project_id'])
    end

    private_class_method :check_feature_flag, :increment_usage_counter
  end
end
