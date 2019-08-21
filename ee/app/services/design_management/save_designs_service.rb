# frozen_string_literal: true

module DesignManagement
  class SaveDesignsService < DesignService
    include RunsDesignActions
    include OnSuccessCallbacks

    MAX_FILES = 10

    def initialize(project, user, params = {})
      super

      @files = params.fetch(:files)
    end

    def execute
      return error("Not allowed!") unless can_create_designs?
      return error("Only #{MAX_FILES} files are allowed simultaneously") if files.size > MAX_FILES

      actions = build_actions
      run_actions(actions)

      success({ designs: actions.map(&:design) })
    rescue ::ActiveRecord::RecordInvalid => e
      error(e.message)
    end

    private

    attr_reader :files
    attr_accessor :paths_in_repo

    def build_actions
      repository.create_if_not_exists

      designs = files.map do |file|
        collection.find_or_create_design!(filename: file.original_filename)
      end

      # Needs to be called before any call to build_design_action
      cache_existence(designs)

      files.zip(designs).map do |(file, design)|
        build_design_action(file, design)
      end
    end

    def build_design_action(file, design)
      action = new_file?(design) ? :create : :update
      content = file_content(file, design.full_path)
      on_success { ::Gitlab::UsageCounters::DesignsCounter.count(action) }

      DesignManagement::DesignAction.new(design, action, content)
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

    def can_create_designs?
      Ability.allowed?(current_user, :create_design, issue)
    end

    def new_file?(design)
      design.new_design? && !on_disk?(design)
    end

    def on_disk?(design)
      paths_in_repo === design.full_path
    end

    def file_content(file, full_path)
      transformer = ::Lfs::FileTransformer.new(project, repository, target_branch)
      transformer.new_file(full_path, file.to_io).content
    end

    def cache_existence(designs)
      paths = designs.map(&:full_path)
      self.paths_in_repo = repository.blobs_metadata(paths).map(&:path).to_set
    end
  end
end
