# frozen_string_literal: true

class PrometheusAlert < ApplicationRecord
  include Sortable

  OPERATORS_MAP = {
    lt: "<",
    eq: "==",
    gt: ">"
  }.freeze

  CUSTOM_METRIC_REGEXP = /\([!]([0-9]+)\)/.freeze

  belongs_to :environment, required: true, validate: true, inverse_of: :prometheus_alerts
  belongs_to :project, required: true, validate: true, inverse_of: :prometheus_alerts
  belongs_to :prometheus_metric, required: true, validate: true, inverse_of: :prometheus_alerts

  has_many :prometheus_alert_events, inverse_of: :prometheus_alert
  has_many :related_issues, through: :prometheus_alert_events

  after_save :clear_prometheus_adapter_cache!
  after_destroy :clear_prometheus_adapter_cache!

  validate :require_valid_environment_project!
  validate :require_valid_metric_project!

  enum operator: [:lt, :eq, :gt]

  delegate :title, to: :prometheus_metric

  scope :for_metric, -> (metric) { where(prometheus_metric: metric) }
  scope :for_project, -> (project) { where(project_id: project) }
  scope :for_environment, -> (environment) { where(environment_id: environment) }

  def self.distinct_projects
    sub_query = self.group(:project_id).select(1)
    self.from(sub_query)
  end

  def self.operator_to_enum(op)
    OPERATORS_MAP.invert.fetch(op)
  end

  def full_query
    "#{query} #{computed_operator} #{threshold}"
  end

  def computed_operator
    OPERATORS_MAP.fetch(operator.to_sym)
  end

  def to_param
    {
      "alert" => title,
      "expr" => full_query,
      "for" => "5m",
      "labels" => {
        "gitlab" => "hook",
        "gitlab_alert_id" => prometheus_metric_id
      }
    }
  end

  def query
    if alert_query.present?
      custom_metric_query
    else
      prometheus_metric.query
    end
  end

  # replace the (!ID) queries with their legend for display
  def abbreviated_query
    return if alert_query.blank?

    abbr_query = alert_query.dup
    embedded_query_metrics(abbr_query).each do |metric|
      abbr_query.gsub!(/\([\!]#{metric.id}\)/, "(#{metric.legend})")
    end
    abbr_query
  end

  private

  def clear_prometheus_adapter_cache!
    environment.clear_prometheus_reactive_cache!(:additional_metrics_environment)
  end

  def require_valid_environment_project!
    return if project == environment&.project

    errors.add(:environment, "invalid project")
  end

  def require_valid_metric_project!
    return if prometheus_metric&.common? || project == prometheus_metric&.project

    errors.add(:prometheus_metric, "invalid project")
  end

  def self.embedded_metric_ids(query)
    return [] if query.blank?

    query.scan(CUSTOM_METRIC_REGEXP).flatten.uniq
  end

  def embedded_query_metrics(query)
    return [] if query.blank?

    metric_ids = self.class.embedded_metric_ids(query)
    return [] unless metric_ids.any?

    # ensure (via .for_project) that metric_ids from another project
    # or for (now) invalid metrics do not get expanded.
    PrometheusMetric.for_project(self.project).where(id: metric_ids)
  end

  # replace (#ID) and (!ID) in the query with their PromQL queries
  # to send to Promethues
  def custom_metric_query
    custom_query = alert_query.dup
    embedded_query_metrics(custom_query).each do |metric|
      custom_query.gsub!(/\([\!]#{metric.id}\)/, "(#{metric.query})")
    end
    '( ' + custom_query + ' )'
  end
end
