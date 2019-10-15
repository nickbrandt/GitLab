# frozen_string_literal: true

module Evidenceable
  extend ActiveSupport::Concern

  included do
    after_update :ensure_evidence

    # Overridden in Release, Milestone and Issue
    def latest_evidences
      raise NotImplementedError, "Please implement 'latest_evidences' in the targeted class."
    end

    # Overridden in Release, Milestone and Issue
    def impacted_releases
      raise NotImplementedError, "Please implement 'impacted_releases' in the targeted class."
    end

    def evidence_summary_keys
      return [] unless latest_evidences.any?

      entity_class&.root_exposures&.map(&:attribute)
    end

    def ensure_evidence
      check_entity_class

      if (saved_changes.keys.map(&:to_sym) & evidence_summary_keys).any?
        impacted_releases.each { |release| Evidence.create!(release: release) }
      end
    end

    def check_entity_class
      raise "Evidenceable module detected in #{self.class.name} - please create an '#{entity_class_name}' class and expose the fields that are relevant to an Evidence summary." unless entity_class
    end

    private

    def entity_class_name
      "Evidences::#{self.class.name}Entity"
    end

    def entity_class
      entity_class_name.safe_constantize
    end
  end
end
