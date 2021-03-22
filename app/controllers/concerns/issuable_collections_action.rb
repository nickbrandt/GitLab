# frozen_string_literal: true

module IssuableCollectionsAction
  extend ActiveSupport::Concern
  include IssuableCollections
  include IssuesCalendar

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def issues
    @issues = issuables_collection
              .non_archived
              .page(params[:page])

    @issuable_meta_data = Gitlab::IssuableMetadata.new(current_user, @issues).data

    if current_user && params[:assignee_username] == current_user.username
      # this means that the user is looking in more detail about their own issues
      # so the count had better be up-to-date just in case there's a caching blip
      Users::UpdateAssignedOpenIssueCountService.new(current_user: current_user, target_user: current_user).execute
    end

    respond_to do |format|
      format.html
      format.atom { render layout: 'xml.atom' }
    end
  end

  def merge_requests
    @merge_requests = issuables_collection.page(params[:page])

    @issuable_meta_data = Gitlab::IssuableMetadata.new(current_user, @merge_requests).data
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def issues_calendar
    render_issues_calendar(issuables_collection)
  end

  private

  def set_not_query_feature_flag(object = nil)
    push_frontend_feature_flag(:not_issuable_queries, object, default_enabled: true)
  end

  def sorting_field
    case action_name
    when 'issues'
      Issue::SORTING_PREFERENCE_FIELD
    when 'merge_requests'
      MergeRequest::SORTING_PREFERENCE_FIELD
    else
      nil
    end
  end

  def finder_type
    case action_name
    when 'issues', 'issues_calendar'
      IssuesFinder
    when 'merge_requests'
      MergeRequestsFinder
    else
      nil
    end
  end

  def finder_options
    super.merge(
      non_archived: true,
      issue_types: Issue::TYPES_FOR_LIST
    )
  end
end
