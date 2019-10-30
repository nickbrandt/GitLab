# frozen_string_literal: true

module EE::Gitlab::Analytics::CycleAnalytics::RecordsFetcher
  extend ::Gitlab::Utils::Override

  override :finder_params
  def finder_params
    super.merge({ ::Group => { group_id: stage.parent_id } })
  end
end
