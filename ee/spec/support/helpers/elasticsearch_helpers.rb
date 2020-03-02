# frozen_string_literal: true

module ElasticsearchHelpers
  def ensure_elasticsearch_index!
    ::Gitlab::Elastic::Helper.refresh_index
  end
end
