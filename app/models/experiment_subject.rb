# frozen_string_literal: true

class ExperimentSubject < ApplicationRecord
  include ::Gitlab::Experimentation::GroupTypes

  belongs_to :experiment
  belongs_to :user
  belongs_to :group
  belongs_to :project

  validates :experiment, presence: true
  validates :variant, presence: true
  validate :must_have_at_least_one_subject

  enum variant: { GROUP_CONTROL => 0, GROUP_EXPERIMENTAL => 1 }

  private

  def must_have_at_least_one_subject
    if [user, group, project].all?(&:blank?)
      errors.add(:base, s_("ExperimentSubject|Must have at least one of User, Group, or Project."))
    end
  end
end
