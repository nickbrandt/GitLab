# frozen_string_literal: true

module ElasticsearchHelpers
  def ensure_elasticsearch_index!
    # Ensure that any enqueued updates are processed
    Elastic::ProcessBookkeepingService::Processor.each do |cls|
      Elastic::ProcessBookkeepingService.new(cls.new).execute
    end

    # Make any documents added to the index visible
    refresh_index!
  end

  def clear_tracking!
    # Ensure that any enqueued updates are ignored
    Elastic::ProcessBookkeepingService::Processor.each do |cls|
      Elastic::ProcessBookkeepingService.clear_tracking!(processor: cls)
    end
  end

  def refresh_index!
    ::Gitlab::Elastic::Helper.default.refresh_index
  end
end
