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

      entity_class&.root_exposures&.map(&:attribute)
    end

    def ensure_evidence
      check_entity_class

      saved_changes.keys.each do |key|
        if evidence_summary_keys.include?(key.to_sym)
          impacted_releases.each do |release|
            Evidence.create!(release: release)
          end
          break
        end
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

    def impacted_releases
      latest_evidences.map(&:release)
    end
  end
end
