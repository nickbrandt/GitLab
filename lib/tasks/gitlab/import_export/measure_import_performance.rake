# frozen_string_literal: true

require 'down/http'
# Import a test project (`gitlabhq`) and measure the time it takes to complete
#
# It uses gitlab:import_export:import task for the actual import
#
# @example
#   bundle exec rake "gitlab:import_export:measure_import_performance[root, root, testingprojectimport, https://gitlab.com/gitlab-org/quality/performance-data/raw/master/gitlabhq_export.tar.gz]"
#   bundle exec rake "gitlab:import_export:measure_import_performance[root, root, testingprojectimport, /path/to/archive]"
#
namespace :gitlab do
  namespace :import_export do
    desc 'GitLab | Import/Export | Measure Import performance'
    task :measure_import_performance, [:username, :namespace_path, :project_path, :archive_path] => :gitlab_environment do |_t, args|
      # Load it here to avoid polluting Rake tasks with Sidekiq test warnings
      require 'sidekiq/testing'

      begin
        # Check that the tarball file is valid
        if args.archive_path.match?(URI.regexp(%w[http https ftp]))
          puts "Tarball is remote, downloading..."
          proj_file = Down::Http.download(args.archive_path)
        else
          proj_file = args.archive_path
        end

        raise Errno::ENOENT unless File.exist?(proj_file)

        # make project name unique in case of any clean-up failures
        project_name = "#{args.project_path}_#{Time.current.to_i}"

        time = Benchmark.measure do
          Rake::Task["gitlab:import_export:import"].invoke(args.username, args.namespace_path, project_name, proj_file)
        end

        puts "Import time: #{time}"

        puts "Removing the project"
        project = Project.find_by_full_path("#{args.namespace_path}/#{project_name}")
        user = User.find_by_username(args.username)

        ::Projects::DestroyService.new(project, user).execute
      ensure
        if proj_file.is_a?(Tempfile)
          proj_file.close
          proj_file.unlink
        end

        puts "Cleanup finished"
      end
    end
  end
end
