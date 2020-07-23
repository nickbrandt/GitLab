# frozen_string_literal: true

class Vulnerabilities::HistoryEntity < Grape::Entity
  present_collection true

  Vulnerabilities::Finding::SEVERITY_LEVELS.keys.each do |level|
    expose level do |object|
      counts(by_severity[level]&.group_by(&:day) || {})
    end
  end

  expose :total do |object|
    counts(by_days)
  end

  private

  def by_days
    items.group_by(&:day)
  end

  def by_severity
    items.group_by(&:severity)
  end

  def items
    object[:items]
  end

  def counts(hash)
    hash.transform_values { |items| items.sum(&:count) } # rubocop: disable CodeReuse/ActiveRecord
  end
end
