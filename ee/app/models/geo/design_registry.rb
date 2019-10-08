# frozen_string_literal: true

class Geo::DesignRegistry < Geo::BaseRegistry
  include ::Delay

  RETRIES_BEFORE_REDOWNLOAD = 5

  belongs_to :project

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

    before_transition any => :pending do |registry, _|
      registry.retry_at    = 0
      registry.retry_count = 0
    end

    event :start_sync! do
      transition [:synced, :failed, :pending] => :started
    end

    event :repository_updated! do
      transition [:synced, :failed, :started] => :pending
    end
  end

  def fail_sync!(message, error, attrs = {})
    new_retry_count = retry_count + 1

    attrs[:state] = :failed
    attrs[:last_sync_failure] = "#{message}: #{error.message}"
    attrs[:retry_count] = new_retry_count
    attrs[:retry_at] = next_retry_time(new_retry_count)

    update!(attrs)
  end

  def finish_sync!(missing_on_primary = false)
    update!(
      missing_on_primary: missing_on_primary,
      retry_count: 0,
      last_sync_failure: nil,
      retry_at: nil,
      force_to_redownload: false
    )

    mark_synced_atomically
  end

  def mark_synced_atomically
    # We can only update registry if state is started.
    # If state is set to pending that means that repository_updated! was called
    # during the sync so we need to reschedule new sync
    num_rows = self.class
                   .where(project_id: project_id)
                   .where(state: 'started')
                   .update_all(state: 'synced')

    num_rows > 0
  end

  def should_be_redownloaded?
    return true if force_to_redownload

    retry_count > RETRIES_BEFORE_REDOWNLOAD
  end
end
