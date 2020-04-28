# frozen_string_literal: true

class Sprint < ApplicationRecord
  include Timebox

  attr_accessor :skip_future_date_validation

  STATE_ID_MAP = {
      upcoming: 1,
      started: 2,
      closed: 3
  }.with_indifferent_access.freeze

  include AtomicInternalId

  has_many :issues
  has_many :merge_requests

  belongs_to :project
  belongs_to :group

  has_internal_id :iid, scope: :project, init: ->(s) { s&.project&.sprints&.maximum(:iid) }
  has_internal_id :iid, scope: :group, init: ->(s) { s&.group&.sprints&.maximum(:iid) }

  validates :start_date, presence: true
  validates :due_date, presence: true

  validate :dates_do_not_overlap, if: :start_or_due_dates_changed?
  validate :future_date, if: :start_or_due_dates_changed?, unless: :skip_future_date_validation

  scope :upcoming, -> { with_state(:upcoming) }
  scope :started, -> { with_state(:started) }

  state_machine :state_id, initial: :upcoming do
    event :start do
      transition upcoming: :started
    end

    event :close do
      transition [:upcoming, :started] => :closed
    end

    state :upcoming, value: Sprint::STATE_ID_MAP[:upcoming]
    state :started, value: Sprint::STATE_ID_MAP[:started]
    state :closed, value: Sprint::STATE_ID_MAP[:closed]
  end

  # Alias to state machine .with_state_id method
  # This needs to be defined after the state machine block to avoid errors
  class << self
    alias_method :with_state, :with_state_id
    alias_method :with_states, :with_state_ids

    def filter_by_state(sprints, state)
      case state
      when 'closed' then sprints.closed
      when 'started' then sprints.started
      when 'opened' then sprints.started.or(sprints.upcoming)
      when 'all' then sprints
      else sprints.upcoming
      end
    end
  end

  def state
    STATE_ID_MAP.key(state_id)
  end

  def state=(value)
    self.state_id = STATE_ID_MAP[value]
  end

  private

  def start_or_due_dates_changed?
    start_date_changed? || due_date_changed?
  end

  # ensure dates do not overlap with other Sprints in the same group/project
  def dates_do_not_overlap
    return unless resource_parent.sprints.where(start_date: start_date..due_date)
                      .or(resource_parent.sprints.where(due_date: start_date..due_date)).exists?

    errors.add(:base, "Dates cannot overlap with other existing Iterations")
  end

  # ensure dates are in the future
  def future_date
    if start_date_changed?
      errors.add(:start_date, "cannot be in the past") if start_date < Date.today
    end

    if due_date_changed?
      errors.add(:due_date, "cannot be in the past") if due_date < Date.today
    end
  end
end
