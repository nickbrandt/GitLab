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
        return error('Issue(s) already assigned', 409)
      end

      if render_not_found_error?
        return error('No Issue found for given params', 404)
      end

      create_issue_links
      success
    end

    private

    def render_conflict_error?
      referenced_issues.present? && (referenced_issues - previous_related_issues).empty?
    end

    def render_not_found_error?
      linkable_issues(referenced_issues).empty?
    end

    def create_issue_links
      issues = linkable_issues(referenced_issues)

      issues.each do |referenced_issue|
        relate_issues(referenced_issue) do |params|
          create_notes(referenced_issue, params)
        end
      end
    end

    def referenced_issues
      @referenced_issues ||= begin
        target_issue = params[:target_issue]

        if params[:issue_references].present?
          extract_issues_from_references
        elsif target_issue
          [target_issue]
        else
          []
        end
      end
    end

    def extract_issues_from_references
      issue_references = params[:issue_references]
      text = issue_references.join(' ')

      extractor = Gitlab::ReferenceExtractor.new(issuable.project, @current_user)
      extractor.analyze(text, extractor_context)

      extractor.issues
    end

    def extractor_context
      {}
    end

    def linkable_issues(issues)
      raise NotImplementedError
    end

    def previous_related_issues
      raise NotImplementedError
    end

    def relate_issues(referenced_issue)
      raise NotImplementedError
    end
  end
end
