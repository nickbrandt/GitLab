# frozen_string_literal: true

class Admin::ElasticsearchController < Admin::ApplicationController
  before_action :check_elasticsearch_web_indexing_feature_flag!

  def check_elasticsearch_web_indexing_feature_flag!
    render_404 unless Feature.enabled?(:elasticsearch_web_indexing)
  end

  # POST
  # Scheduling indexing jobs
  def enqueue_index
    ::Elastic::IndexProjectsService.new.execute

    notice = _('Elasticsearch indexing started')
    queue_link = helpers.link_to(_('(check progress)'), sidekiq_path + '/queues/elastic_full_index')
    flash[:notice] = "#{notice} #{queue_link}".html_safe

    redirect_back_or_default
  end
end
