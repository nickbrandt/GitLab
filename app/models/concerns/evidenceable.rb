# frozen_string_literal: true

module Evidenceable
  extend ActiveSupport::Concern

  included do
    after_update :ensure_evidence

    # Overridden in Release, Milestone and Issue
    def latest_evidences
      raise "Please implement 'latest_evidences' in the targetted class."
    end

    def evidence_summary_keys
      return [] unless latest_evidences.any?

      entity_class = "Evidence#{self.class.name}Entity".safe_constantize
      return [] unless entity_class

      entity_class.root_exposures.map(&:attribute)
    end

    def ensure_evidence
      saved_changes.keys.each do |key|
        if evidence_summary_keys.include?(key.to_sym)
          impacted_releases.each do |release|
            Evidence.create!(release: release)
          end
          break
        end
      end
    end

    def impacted_releases
      latest_evidences.map(&:release)
    end
  end
end
