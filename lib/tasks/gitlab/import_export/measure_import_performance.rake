# frozen_string_literal: true

# Import a test project (`gitlabhq`) and measure the time it takes to complete
#
# It uses gitlab:import_export:import task for the actual import
#
# @example
#   bundle exec rake "gitlab:import_export:measure_import_performance"
#
namespace :gitlab do
  namespace :import_export do
    desc 'GitLab | Import/Export | Measure Import performance'
    task :measure_import_performance, [:username, :namespace_path, :project_path, :archive_path] => :gitlab_environment do |_t, args|
      # Load it here to avoid polluting Rake tasks with Sidekiq test warnings
      require 'sidekiq/testing'

      # TODO: do I need this?
      # warn_user_is_not_gitlab

      # TODO: the flow;
      # run
      # measure
      # cleanup
      Rake::Task["gitlab:import_export:import"].invoke(args.username, args.namespace_path, args.project_path, args.archive_path)
    end
  end
end
