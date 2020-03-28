# frozen_string_literal: true

module ElasticsearchHelpers
  def ensure_elasticsearch_index!
    # Ensure that any enqueued updates are processed
    Elastic::ProcessBookkeepingService.new.execute

    # Make any documents added to the index visible
    refresh_index!
  end

  def refresh_index!
    ::Gitlab::Elastic::Helper.refresh_index
  end
end
