# frozen_string_literal: true

class Evidence < ApplicationRecord
  belongs_to :release

  before_create :generate_summary

  validates :release, presence: true

  validate :release_fields
  validate :milestone_fields
  validate :issue_fields

  def sha
    return unless summary

    Gitlab::CryptoHelper.sha256(summary)
  end

  private

  def generate_summary
    self.summary = EvidenceReleaseSerializer.new.represent(release) # rubocop: disable CodeReuse/Serializer
  end

  def release_fields
    return unless release.present?

    errors.add(:base, 'must be provided a release tag') unless release.tag.present?
    errors.add(:base, 'must be provided a release project') unless release.project.present?
    errors.add(:base, 'must be provided a release description') unless release.description.present?
  end

  def milestone_fields
    return unless milestones.any?

    errors.add(:base, ' - all milestones must have titles') if milestones.map(&:title).any?(&:blank?)
    errors.add(:base, ' - all milestones must have states') if milestones.map(&:state).any?(&:blank?)
  end

  def issue_fields
    return unless milestones.any?

    issues = milestones.map(&:issues).flatten
    return unless issues.any?

    errors.add(:base, '- all issues must have titles') if issues.map(&:title).any?(&:blank?)
    errors.add(:base, '- all issues must have states') if issues.map(&:state).any?(&:blank?)
    errors.add(:base, '- all issues must have an author') if issues.map(&:author_id).any?(&:blank?)
  end

  def milestones
    @milestones ||= release&.milestones || []
  end
end
