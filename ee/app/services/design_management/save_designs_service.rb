# frozen_string_literal: true

module DesignManagement
  class SaveDesignsService < ::BaseService
    MAX_FILES = 10

    def initialize(project, user, params = {})
      super

      @issue = params.fetch(:issue)
      @files = params.fetch(:files)
      @success_callbacks = []
    end

    def execute
      return error("Not allowed!") unless can_create_designs?
      return error("Only #{MAX_FILES} files are allowed simultaneously") if files.size > MAX_FILES

      save_designs!

      success({ designs: updated_designs })
    rescue ::Gitlab::Git::BaseError, ::ActiveRecord::RecordInvalid => e
      error(e.message)
    end

    private

    attr_reader :files, :issue

    def success(*_)
      while cb = @success_callbacks.pop
        cb.call
      end

      super
    end

    def on_success(&block)
      @success_callbacks.push(block)
    end

    def save_designs!
      commit_sha = create_and_commit_designs!
      ::DesignManagement::Version.create_for_designs(updated_designs, commit_sha)
    end

    def create_and_commit_designs!
      repository.create_if_not_exists

      # Do not inline `build_repository_action` here!
      # We have to do this as two *separate* calls to #map so that the call
      # to `new_file?` does not accidentally cache the wrong data half-way
      # through the operation.
      corresponding_designs = files.map do |file|
        collection.find_or_create_design!(filename: file.original_filename)
      end

      actions = files.zip(corresponding_designs).map do |(file, design)|
        build_repository_action(file, design)
      end

      repository.multi_action(current_user,
                              branch_name: target_branch,
                              message: commit_message,
                              actions: actions)
    end

    def build_repository_action(file, design)
      action = new_file?(design) ? :create : :update
      on_success { ::Gitlab::UsageCounters::DesignsCounter.count(action) }

      {
        action: action,
        file_path: design.full_path,
        content: file_content(file, design.full_path)
      }
    end

    def collection
      issue.design_collection
    end

    def repository
      project.design_repository
    end

    def project
      issue.project
    end

    def target_branch
      repository.root_ref || "master"
    end

    def commit_message
      <<~MSG
      Updated #{files.size} #{'designs'.pluralize(files.size)}

      #{formatted_file_list}
      MSG
    end

    def formatted_file_list
      filenames.map { |name| "- #{name}" }.join("\n")
    end

    def filenames
      @filenames ||= files.map(&:original_filename)
    end

    def updated_designs
      @updated_designs ||= collection.designs.select { |design| filenames.include?(design.filename) }
    end

    def can_create_designs?
      Ability.allowed?(current_user, :create_design, issue)
    end

    def new_file?(design)
      design.new_design? && existing_metadata.none? { |blob| blob.path == design.full_path }
    end

    def file_content(file, full_path)
      return file.to_io if ::Feature.disabled?(:store_designs_in_lfs, default_enabled: true)

      transformer = ::Lfs::FileTransformer.new(project, repository, target_branch)
      transformer.new_file(full_path, file.to_io).content
    end

    def existing_metadata
      @existing_metadata ||= begin
                               paths = updated_designs.map(&:full_path)
                               repository.blobs_metadata(paths)
                             end
    end
  end
end
