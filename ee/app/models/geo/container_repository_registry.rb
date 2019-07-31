# frozen_string_literal: true

class Geo::ContainerRepositoryRegistry < Geo::BaseRegistry
  include ::Delay

  belongs_to :container_repository

  scope :repository_id_not_in, -> (ids) { where.not(container_repository_id: ids) }
  scope :failed, -> { with_state(:failed) }
  scope :synced, -> { with_state(:synced) }
  scope :retry_due, -> { where(arel_table[:retry_at].eq(nil).or(arel_table[:retry_at].lt(Time.now))) }

  state_machine :state, initial: :pending do
    state :started
    state :synced
    state :failed
    state :pending

    before_transition any => :started do |registry, _|
      registry.last_synced_at = Time.now
    end

    before_transition any => :synced do |registry, _|
      registry.retry_count       = 0
      registry.retry_at          = nil
      registry.last_sync_failure = nil
    end

    before_transition any => :pending do |registry, _|
      registry.retry_at    = 0
      registry.retry_count = 0
    end

    event :start_sync! do
      transition [:synced, :failed, :pending] => :started
    end

    event :finish_sync! do
      transition started: :synced
    end

    event :repository_updated! do
      transition [:synced, :failed, :started] => :pending
    end
  end

  def self.pluck_container_repository_key
    where(nil).pluck(:container_repository_id)
  end

  def fail_sync!(message, error)
    new_retry_count = retry_count + 1

    update!(
      state: :failed,
      last_sync_failure: "#{message}: #{error.message}",
      retry_count: new_retry_count,
      retry_at: next_retry_time(new_retry_count)
    )
  end
end
