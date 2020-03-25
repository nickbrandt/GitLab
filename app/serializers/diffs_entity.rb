# frozen_string_literal: true

class DiffsEntity < Grape::Entity
  include DiffHelper
  include RequestAwareEntity
  include Gitlab::Utils::StrongMemoize

  expose :real_size
  expose :size

  expose :branch_name do |diffs|
    merge_request&.source_branch
  end

  expose :target_branch_name do |diffs|
    merge_request&.target_branch
  end

  expose :commit do |diffs, options|
    if options[:commit]
      neighbors = commits(options[:commit].id) if options[:commit]
      prev_commit_id = neighbors[:prev_commit_id]
      next_commit_id = neighbors[:next_commit_id]
    end

    CommitEntity.represent options[:commit], options.merge(
      type: :full,
      commit_url_params: { merge_request_iid: merge_request&.iid },
      pipeline_ref: merge_request&.source_branch,
      pipeline_project: merge_request&.source_project,
      prev_commit_id: prev_commit_id,
      next_commit_id: next_commit_id
    )
  end

  expose :context_commits, using: API::Entities::Commit, if: -> (diffs, options) { merge_request&.project&.context_commits_enabled? } do |diffs|
    options[:context_commits]
  end

  expose :merge_request_diff, using: MergeRequestDiffEntity do |diffs|
    options[:merge_request_diff]
  end

  expose :start_version, using: MergeRequestDiffEntity do |diffs|
    options[:start_version]
  end

  expose :latest_diff do |diffs|
    options[:latest_diff]
  end

  expose :latest_version_path, if: -> (*) { merge_request } do |diffs|
    diffs_project_merge_request_path(merge_request&.project, merge_request)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  expose :added_lines do |diffs|
    diffs.raw_diff_files.sum(&:added_lines)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  expose :removed_lines do |diffs|
    diffs.raw_diff_files.sum(&:removed_lines)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  expose :render_overflow_warning do |diffs|
    render_overflow_warning?(diffs)
  end

  expose :email_patch_path, if: -> (*) { merge_request } do |diffs|
    merge_request_path(merge_request, format: :patch)
  end

  expose :plain_diff_path, if: -> (*) { merge_request } do |diffs|
    merge_request_path(merge_request, format: :diff)
  end

  expose :diff_files do |diffs, options|
    submodule_links = Gitlab::SubmoduleLinks.new(merge_request.project.repository)
    DiffFileEntity.represent(diffs.diff_files, options.merge(submodule_links: submodule_links))
  end

  expose :merge_request_diffs, using: MergeRequestDiffEntity, if: -> (_, options) { options[:merge_request_diffs]&.any? } do |diffs|
    options[:merge_request_diffs]
  end

  def merge_request
    options[:merge_request]
  end

  def commit_ids
    strong_memoize(:commit_ids) do
      [nil] + merge_request.commits.collect(&:id) + [nil]
    end
  end

  def commits(id)
    commit_ids.each_cons(3) do |prev_commit, commit, next_commit|
      { prev_commit_id: prev_commit, next_commit_id: next_commit } if commit == id
    end
  end
end
