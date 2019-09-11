# frozen_string_literal: true

class Analytics::ProductivityAnalyticsController < Analytics::ApplicationController
  check_feature_flag Gitlab::Analytics::PRODUCTIVITY_ANALYTICS_FEATURE_FLAG

  before_action :load_group
  before_action :load_project
  before_action :check_feature_availability!
  before_action :authorize_view_productivity_analytics!

  include IssuableCollections

  def show
    respond_to do |format|
      format.html
      format.json do
        metric = params.fetch('metric_type', ProductivityAnalytics::DEFAULT_TYPE)

        data = case params['chart_type']
               when 'scatterplot'
                 productivity_analytics.scatterplot_data(type: metric)
               when 'histogram'
                 productivity_analytics.histogram_data(type: metric)
               else
                 include_relations(paginate(productivity_analytics.merge_requests_extended)).map do |merge_request|
                   serializer.represent(merge_request, {}, ProductivityAnalyticsMergeRequestEntity)
                 end
               end

        render json: data, status: :ok
      end
    end
  end

  private

  def paginate(merge_requests)
    merge_requests.page(params[:page]).per(params[:per_page]).tap do |paginated_data|
      response.set_header('X-Per-Page', paginated_data.limit_value.to_s)
      response.set_header('X-Page', paginated_data.current_page.to_s)
      response.set_header('X-Next-Page', paginated_data.next_page.to_s)
      response.set_header('X-Prev-Page', paginated_data.prev_page.to_s)
      response.set_header('X-Total', paginated_data.total_count.to_s)
      response.set_header('X-Total-Pages', paginated_data.total_pages.to_s)
    end
  end

  def authorize_view_productivity_analytics!
    return render_403 unless can?(current_user, :view_productivity_analytics, @group || :global)
  end

  def check_feature_availability!
    return render_404 unless ::License.feature_available?(:productivity_analytics)
    return render_404 if @group && !@group.root_ancestor.feature_available?(:productivity_analytics)
  end

  def load_group
    return unless params['group_id']

    @group = find_routable!(Group, params['group_id'])
  end

  def load_project
    return unless @group && params['project_id']

    @project = find_routable!(@group.projects, params['project_id'])
  end

  def serializer
    @serializer ||= BaseSerializer.new(current_user: current_user)
  end

  def finder_type
    ProductivityAnalyticsFinder
  end

  def default_state
    'merged'
  end

  def productivity_analytics
    @productivity_analytics ||= ProductivityAnalytics.new(merge_requests: finder.execute, sort: params[:sort])
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def include_relations(paginated_mrs)
    # Due to Rails bug: https://github.com/rails/rails/issues/34889 we can't use .includes statement
    # to avoid N+1 call when we load custom columns.
    # So we load relations manually here.
    preloader = ActiveRecord::Associations::Preloader.new
    preloader.preload(paginated_mrs, { author: [], target_project: { namespace: :route } })
    paginated_mrs
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
