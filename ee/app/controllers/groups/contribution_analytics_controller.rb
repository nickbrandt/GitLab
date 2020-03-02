# frozen_string_literal: true

class Groups::ContributionAnalyticsController < Groups::ApplicationController
  before_action :group
  before_action :check_contribution_analytics_available!

  layout 'group'

  def show
    @start_date = data_collector.from

    respond_to do |format|
      format.html
      format.json do
        render json: GroupAnalyticsSerializer
          .new(data_collector: data_collector)
          .represent(data_collector.users), status: :ok
      end
    end
  end

  private

  def data_collector
    @data_collector ||= Gitlab::ContributionAnalytics::DataCollector
      .new(group: @group, from: params[:start_date] || 1.week.ago.to_date)
  end

  def check_contribution_analytics_available!
    render_404 unless @group.feature_available?(:contribution_analytics) || LicenseHelper.show_promotions?(current_user)
  end
end
