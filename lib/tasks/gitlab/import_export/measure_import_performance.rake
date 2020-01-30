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

      # make project name unique in case of any clean-up failures
      project_name = "#{args.project_path}_#{Time.current.to_i}"
      time = Benchmark.measure do
        Rake::Task["gitlab:import_export:import"].invoke(args.username, args.namespace_path, project_name, args.archive_path)
      end

      puts "Import time: #{time}"

      puts "Removing the project"
      project = Project.find_by_full_path("#{args.namespace_path}/#{project_name}")
      user = User.find_by_username(args.username)

      ::Projects::DestroyService.new(project, user).execute
      puts "Cleanup finished"
    end
  end
end
