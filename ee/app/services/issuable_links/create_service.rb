# frozen_string_literal: true

module IssuableLinks
  class CreateService < BaseService
    attr_reader :issuable, :current_user, :params

    def initialize(issuable, user, params)
      @issuable, @current_user, @params = issuable, user, params.dup
    end

    def execute
      # If ALL referenced issues are already assigned to the given epic it renders a conflict status,
      # otherwise create issue links for the issues which
      # are still not assigned and return success message.
      if render_conflict_error?
        return error(issuables_assigned_message, 409)
      end

      if render_not_found_error?
        return error(issuables_not_found_message, 404)
      end

      create_links
      success
    end

    private

    def render_conflict_error?
      referenced_issuables.present? && (referenced_issuables - previous_related_issuables).empty?
    end

    def render_not_found_error?
      linkable_issuables(referenced_issuables).empty?
    end

    def create_links
      objects = linkable_issuables(referenced_issuables)

      objects.each do |referenced_object|
        relate_issuables(referenced_object) do |params|
          create_notes(referenced_object, params)
        end
      end
    end

    def referenced_issuables
      @referenced_issuables ||= begin
        target_issuable = params[:target_issuable]

        if params[:issuable_references].present?
          extract_references
        elsif target_issuable
          [target_issuable]
        else
          []
        end
      end
    end

    def extract_references
      issuable_references = params[:issuable_references]
      text = issuable_references.join(' ')

      extractor = Gitlab::ReferenceExtractor.new(issuable.project, current_user)
      extractor.analyze(text, extractor_context)

      references(extractor)
    end

    def references(extractor)
      extractor.issues
    end

    def extractor_context
      {}
    end

    def linkable_issuables(objects)
      raise NotImplementedError
    end

    def previous_related_issuables
      raise NotImplementedError
    end

    def relate_issuables(referenced_object)
      raise NotImplementedError
    end

    def issuables_assigned_message
      'Issue(s) already assigned'
    end

    def issuables_not_found_message
      'No Issue found for given params'
    end
  end
end
