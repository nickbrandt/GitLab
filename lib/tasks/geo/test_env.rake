require 'sidekiq/testing/inline'

module Geo
  class TestEnv
    BATCH_SIZE = 250

    TMP_TEST_PATH = Rails.root.join('tmp', 'tests', 'geo')

    REPOSITORIES_URLS = [
      'https://gitlab.com/gitlab-org/gitlab-test.git'
    ]

    attr_reader :opts

    def initialize(opts = {})
      @opts = opts
    end

    def seed!
      setup_test_path!
      setup_sample_repositories!
      create_mass_projects!
      copy_repositories_to_projects!
    end

    private

    def setup_test_path!
      FileUtils.mkdir_p(TMP_TEST_PATH)
    end

    def setup_sample_repositories!
      puts "\n==> Setting up sample repositories..."
      start = Time.now

      REPOSITORIES_URLS.each do |project_url|
        clone_repository(project_url)
      end

      puts "    Repositories setup in #{Time.now - start} seconds...\n"
    end

    def clone_repository(clone_url)
      repo_name = clone_url[/.+\/(?<name>.+).git/, 1]
      repo_path = File.join(TMP_TEST_PATH, repo_name)
      repo_path_bare = "#{repo_path}_bare"

      unless File.directory?(repo_path)
        system(*%W(#{Gitlab.config.git.bin_path} clone -q #{clone_url} #{repo_path}))
      end

      unless File.directory?(repo_path_bare)
        system(git_env, *%W(#{Gitlab.config.git.bin_path} clone -q --bare #{repo_path} #{repo_path_bare}))
      end
    end

    def copy_repositories_to_projects!
      puts "\n==> Copying repositories..."
      start = Time.now

      Project.find_in_batches(batch_size: BATCH_SIZE) do |batch|
        batch.each do |project|
          copy_repository(project, REPOSITORIES_URLS.sample)
        end
      end

      puts "    Repositories copied in #{Time.now - start} seconds...\n"
    end

    def copy_repository(project, clone_url)
      target_repo_path = File.expand_path(File.join(project.repository_storage_path, "#{project.full_path}.git"))
      FileUtils.mkdir_p(target_repo_path)

      if take_chance(12)
        system(git_env, *%W(#{Gitlab.config.git.bin_path} init -q --bare #{target_repo_path}))
      else
        repo_name = clone_url[/.+\/(?<name>.+).git/, 1]
        source_repo_path = File.expand_path(File.join(TMP_TEST_PATH, "#{repo_name}_bare"))

        FileUtils.cp_r("#{source_repo_path}/.", target_repo_path)
      end

      FileUtils.chmod_R 0755, target_repo_path
    end

    # Prevent developer git configurations from being persisted to test repositories
    def git_env
      { 'GIT_TEMPLATE_DIR' => '' }
    end

    # TODO: Create forked projects
    # TODO: Create wiki repositories
    def create_mass_projects!(count = 750)
      puts "\n==> Creating #{count} projects..."
      start = Time.now

      # Disable database insertion logs so speed isn't limited by ability to print to console
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      Sidekiq::Testing.inline! do
        create_projects_by_visibility!(count / 3, :private)
        create_projects_by_visibility!(count / 3, :internal)
        create_projects_by_visibility!(count / 3, :public)
        create_missing_project_features!
        create_missing_project_statistics!
      end

      # Reset logging
      ActiveRecord::Base.logger = old_logger

      puts "    #{count} projects created in #{Time.now - start} seconds...\n"
    end

    def create_projects_by_visibility!(count, visibility)
      users = User.limit(100)
      groups = Group.limit(100)
      namespaces = users + groups

      Project.insert_using_generate_series(1, count, debug: false) do |sql|
        project_name = raw("'geo_#{visibility}_project_' || seq")
        namespace = namespaces.sample

        sql.name = project_name
        sql.path = project_name
        sql.creator_id = namespace.is_a?(Group) ? namespace.owner_id : namespace.id
        sql.namespace_id = namespace.is_a?(Group) ? namespace.id : namespace.namespace_id
        sql.visibility_level = Gitlab::VisibilityLevel.level_value(visibility.to_s)
        sql.last_activity_at = Time.now
        sql.last_repository_updated_at = Time.now
      end
    end

    def create_missing_project_features!
      ActiveRecord::Base.connection.execute <<-SQL
        INSERT INTO project_features (
          project_id,
          merge_requests_access_level,
          issues_access_level,
          wiki_access_level,
          snippets_access_level,
          builds_access_level,
          created_at,
          updated_at,
          repository_access_level
        )
        SELECT projects.id AS project_id,
              #{ProjectFeature::ENABLED} AS merge_requests_access_level,
              #{ProjectFeature::ENABLED} AS issues_access_level,
              #{ProjectFeature::ENABLED} AS wiki_access_level,
              #{ProjectFeature::ENABLED} AS snippets_access_level,
              #{ProjectFeature::ENABLED} AS builds_access_level,
              NOW() AS created_at,
              NOW() as updated_at,
              #{ProjectFeature::ENABLED} AS repository_access_level
        FROM projects LEFT JOIN project_features ON projects.id = project_features.project_id
        WHERE project_features.project_id IS NULL;
      SQL
    end

    # TODO: ProjectStatistics#update_storage_size
    def create_missing_project_statistics!
      ActiveRecord::Base.connection.execute <<-SQL
        INSERT INTO project_statistics (
          project_id,
          namespace_id
        )
        SELECT projects.id AS project_id,
               projects.namespace_id AS namespace_id
        FROM projects LEFT JOIN project_statistics ON projects.id = project_statistics.project_id
        WHERE project_statistics.project_id IS NULL;
      SQL
    end

    def take_chance(prob)
      1 + rand(prob) === 1
    end
  end
end

namespace :geo do
  namespace :test_env do |ns|
    task seed: :environment do
      Gitlab::Seeder.quiet do
        projects = Geo::TestEnv.new
        projects.seed!
      end
    end
  end
end
