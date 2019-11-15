# frozen_string_literal: true

module DescriptionDiffActions
  extend ActiveSupport::Concern

  def description_diff
    return render_404 unless issuable.resource_parent.feature_available?(:description_diffs)

    current_version = issuable.description_versions.find(params[:version_id])
    previous_version = if params[:start_version_id].present?
                         issuable.description_versions.find(params[:start_version_id]).previous_version
                       else
                         current_version.previous_version
                       end

    return render_404 if previous_version.nil?

    diff = Gitlab::Diff::CharDiff.new(previous_version.description, current_version.description)
    diff.generate_diff

    render html: diff.to_html
  end
end
