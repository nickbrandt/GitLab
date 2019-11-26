# frozen_string_literal: true

class ContainerExpirationPolicy < ApplicationRecord
  belongs_to :project, inverse_of: :container_expiration_policy

  delegate :container_repositories, to: :project

  validates :project, presence: true
  validates :enabled, inclusion: { in: [true, false] }
  validates :cadence, presence: true, inclusion: { in: ->(_) { self.cadence_options.stringify_keys } }
  validates :older_than, inclusion: { in: ->(_) { self.older_than_options.stringify_keys } }, allow_nil: true
  validates :keep_n, inclusion: { in: ->(_) { self.keep_n_options.keys } }, allow_nil: true

  scope :enabled, -> { where(enabled: true) }
  scope :runnable_schedules, -> { enabled.where("next_run_at < ?", Time.zone.now) }
  scope :preloaded, -> { preload(:project) }

  before_save :set_next_run_at

  def self.keep_n_options
    {
      1 => _('%{tags} tag per image name') % { tags: 1 },
      5 => _('%{tags} tags per image name') % { tags: 5 },
      10 => _('%{tags} tags per image name') % { tags: 10 },
      25 => _('%{tags} tags per image name') % { tags: 25 },
      50 => _('%{tags} tags per image name') % { tags: 50 },
      100 => _('%{tags} tags per image name') % { tags: 100 }
    }
  end

  def self.cadence_options
    {
      '1d': _('Every day'),
      '7d': _('Every week'),
      '14d': _('Every two weeks'),
      '1month': _('Every month'),
      '3month': _('Every three months')
    }
  end

  def self.older_than_options
    {
      '7d': _('%{days} days until tags are automatically removed') % { days: 7 },
      '14d': _('%{days} days until tags are automatically removed') % { days: 14 },
      '30d': _('%{days} days until tags are automatically removed') % { days: 30 },
      '90d': _('%{days} days until tags are automatically removed') % { days: 90 }
    }
  end

  def set_next_run_at
    self.next_run_at = Time.zone.now + ChronicDuration.parse(cadence).seconds
  end

  # To be extracted with technical debt issue https://gitlab.com/gitlab-org/gitlab/issues/191331
  def schedule_next_run!
    save! # executes set_next_run_at
  rescue ActiveRecord::RecordInvalid
    update_column(:next_run_at, nil) # update without validation
  end
end
