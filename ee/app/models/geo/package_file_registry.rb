# frozen_string_literal: true

class Geo::PackageFileRegistry < Geo::BaseRegistry
  include ::Delay
  include ShaAttribute

  def self.declarative_policy_class
    'Geo::RegistryPolicy'
  end

  STATE_VALUES = {
    pending: 0,
    started: 1,
    synced: 2,
    failed: 3
  }.freeze

  belongs_to :package_file, class_name: 'Packages::PackageFile'

  scope :never, -> { where(last_synced_at: nil) }
  scope :failed, -> { with_state(:failed) }
  scope :synced, -> { with_state(:synced) }
  scope :retry_due, -> { where(arel_table[:retry_at].eq(nil).or(arel_table[:retry_at].lt(Time.current))) }
  scope :ordered, -> { order(:id) }

  state_machine :state, initial: :pending do
    state :pending, value: STATE_VALUES[:pending]
    state :started, value: STATE_VALUES[:started]
    state :synced, value: STATE_VALUES[:synced]
    state :failed, value: STATE_VALUES[:failed]

    before_transition any => :started do |registry, _|
      registry.last_synced_at = Time.current
    end

    before_transition any => :pending do |registry, _|
      registry.retry_at = 0
      registry.retry_count = 0
    end

    before_transition any => :failed do |registry, _|
      registry.retry_count += 1
      registry.retry_at = registry.next_retry_time(registry.retry_count)
    end

    before_transition any => :synced do |registry, _|
      registry.retry_count = 0
      registry.last_sync_failure = nil
      registry.retry_at = nil
    end

    event :start do
      transition [:pending, :synced, :failed] => :started
    end

    event :synced do
      transition [:started] => :synced
    end

    event :failed do
      transition [:started] => :failed
    end

    event :resync do
      transition [:synced, :failed] => :pending
    end
  end

  sha_attribute :verification_checksum
  sha_attribute :verification_checksum_mismatched

  # @return [Geo::PackageFileRegistry] an instance of this class
  def self.for_model_record_id(id)
    find_or_initialize_by(package_file_id: id)
  end

  def self.state_value(state_string)
    STATE_VALUES[state_string]
  end

  # Override state machine failed! event method to record a failure message at
  # the same time.
  #
  # @param [String] message error information
  # @param [StandardError] error exception
  def failed!(message, error = nil)
    self.last_sync_failure = message
    self.last_sync_failure += ": #{error.message}" if error.respond_to?(:message)

    super()
  end
end
