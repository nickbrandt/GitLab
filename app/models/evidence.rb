# frozen_string_literal: true

class Evidence < ApplicationRecord
  belongs_to :release, optional: false

  before_validation :generate_summary

  default_scope { order(created_at: :asc) }

  def sha
    return unless summary

    Gitlab::CryptoHelper.sha256(summary)
  end

  def milestones
    @milestones ||= release.milestones.includes(:issues)
  end

  private

  def generate_summary
    self.summary = Evidences::EvidenceSerializer.new.represent(self) # rubocop: disable CodeReuse/Serializer
  end
end
