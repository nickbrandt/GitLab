require 'sidekiq/testing/inline'

module Geo
  class TestEnv
    BATCH_SIZE = 250
    MASS_PROJECTS_COUNT = 30_000
    TMP_TEST_PATH = Rails.root.join('tmp', 'tests', 'geo')

    REPOSITORIES_URLS = [
      'https://gitlab.com/gitlab-org/gitlab-test.git'
    ].freeze

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

      REPOSITORIES_URLS.each do |clone_url|
        repo_name = clone_url[/.+\/(?<name>.+).git/, 1]
        repo_path = File.join(TMP_TEST_PATH, repo_name)

        clone_repository(repo_path, clone_url)
        create_bare_repository("#{repo_path}.wiki")
      end

      puts "    Sample repositories setup in #{pretty_duration(Time.now - start)}...\n"
    end

    def clone_repository(repo_path, clone_url)
      repo_path_bare = "#{repo_path}_bare"

      unless File.directory?(repo_path)
        system(*%W(#{Gitlab.config.git.bin_path} clone -q #{clone_url} #{repo_path}))
      end

      unless File.directory?(repo_path_bare)
        system(git_env, *%W(#{Gitlab.config.git.bin_path} clone -q --bare #{repo_path} #{repo_path_bare}))
      end
    end

    def create_bare_repository(repo_path)
      system(git_env, *%W(#{Gitlab.config.git.bin_path} init -q --bare #{repo_path}))
    end

    def copy_repositories_to_projects!
      puts "\n==> Copying repositories..."
      start = Time.now

      Project.find_in_batches(batch_size: BATCH_SIZE) do |batch|
        batch.each do |project|
          copy_repository(project, REPOSITORIES_URLS.sample)
        end
      end

      puts "    #{MASS_PROJECTS_COUNT} repositories copied in #{pretty_duration(Time.now - start)}...\n"
    end

    def copy_repository(project, clone_url)
      target_repo_path = File.expand_path(File.join(project.repository_storage_path, "#{project.full_path}.git"))
      target_wiki_path = File.expand_path(File.join(project.repository_storage_path, "#{project.full_path}.wiki.git"))
      return if File.exists?(target_repo_path)

      FileUtils.mkdir_p(target_repo_path)
      FileUtils.mkdir_p(target_wiki_path)

      if take_chance(12)
        create_bare_repository(target_repo_path)
        create_bare_repository(target_wiki_path)
      else
        repo_name = clone_url[/.+\/(?<name>.+).git/, 1]
        source_repo_path = File.expand_path(File.join(TMP_TEST_PATH, repo_name))

        FileUtils.cp_r("#{source_repo_path}_bare/.", target_repo_path)
        FileUtils.cp_r("#{source_repo_path}.wiki/.", target_wiki_path)
      end

      FileUtils.chmod_R 0755, target_repo_path
      FileUtils.chmod_R 0755, target_wiki_path
    end

    # Prevent developer git configurations from being persisted to test repositories
    def git_env
      { 'GIT_TEMPLATE_DIR' => '' }
    end

    # TODO: Create forked projects
    # TODO: Create wiki repositories
    def create_mass_projects!
      puts "\n==> Creating #{MASS_PROJECTS_COUNT} projects..."
      start = Time.now

      # Disable database insertion logs so speed isn't limited by ability to print to console
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      Sidekiq::Testing.inline! do
        create_projects_by_visibility!(MASS_PROJECTS_COUNT / 3, :private)
        create_projects_by_visibility!(MASS_PROJECTS_COUNT / 3, :internal)
        create_projects_by_visibility!(MASS_PROJECTS_COUNT / 3, :public)
        create_missing_project_features!
        create_missing_project_statistics!
      end

      # Reset logging
      ActiveRecord::Base.logger = old_logger

      puts "    #{MASS_PROJECTS_COUNT} projects created in #{pretty_duration(Time.now - start)}...\n"
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

    def pretty_duration(duration)
      Time.at(duration).utc.strftime('%Hh %Mm %Ss')
    end
  end
end

module Geo
  class RandomCommitGenerator
    TMP_TEST_PATH = Rails.root.join('tmp', 'tests', 'geo')

    EXTENSIONS = %w(css js html rb txt png).freeze

    def generate(project)
      puts "\n==> Generating random changes for project #{project.full_path}..."
      repo_path = File.join(TMP_TEST_PATH, project.path)
      clone_url = project.ssh_url_to_repo
      clone_repository(repo_path, clone_url)

      directories, files = traverse_root_path(repo_path)
      remove_random_files(directories, files)
      create_random_files(repo_path)
      commit_changes(repo_path)
    end

    private

    def clone_repository(repo_path, clone_url)
      unless File.directory?(repo_path)
        puts "    Cloning project in #{repo_path}"
        system(*%W(#{Gitlab.config.git.bin_path} clone -q #{clone_url} #{repo_path}))
      end
    end

    def traverse_root_path(path)
      directories, files = [], []

      Dir.foreach(path) do |file|
        next if file.start_with?('.')

        fullpath = File.join(path, file)

        if File.directory?(fullpath)
          directories << fullpath
        else
          files << fullpath
        end
      end

      # Shuffle directories and files so that they're explored in a different order each time
      [directories.shuffle, files.shuffle!]
    end

    def remove_random_files(directories, files)
      # Remove some directories
      directories.delete_if do |directory|
        if rand > 0.999
          FileUtils.rm_rf(directory)
          puts "    Removed directory: #{directory}\n"
          true
        else
          false
        end
      end

      max_removals  = random(2)
      removals = 0

      files.delete_if do |file|
        if random > 0.8 && removals < max_removals
          FileUtils.rm_rf(file)
          removals += 1
          puts "    Removed file: #{file}\n"
          true
        else
          false
        end
      end
    end

    def create_random_files(repo_path)
      max_new_dirs  = random(3)
      max_new_files = random(10)

      max_new_files.times do
        file = make_random_file(repo_path)
        puts "    Created file: #{file}\n"
      end

      max_new_dirs.times do
        directory = make_random_directory(repo_path)
        file = make_random_file(directory)
        puts "    Created file: #{file}\n"
      end
    end

    def make_random_directory(path)
      make_directory(path, make_random_name)
    end

    def make_random_file(path)
      make_empty_file(path, "#{make_random_name}.#{make_random_extension}")
    end

    def make_empty_file(path, name)
      fullpath = File.join(path, name)
      File.open(fullpath, 'a') {}
      fullpath
    end

    def make_directory(path, name)
      fullpath = File.join(path, name)

      unless File.exists?(fullpath)
        FileUtils.mkdir_p(fullpath)
      end

      fullpath
    end

    def make_random_name(length = 8)
      SecureRandom.hex(length / 2)
    end

    def make_random_extension
      EXTENSIONS.sample
    end

    def commit_changes(repo_path)
      puts "\n==> Committing changes..."
      system(*%W(#{Gitlab.config.git.bin_path} -C #{repo_path} add .))
      system(*%W(#{Gitlab.config.git.bin_path} -C #{repo_path} commit -m Commit-#{Time.now.strftime('%Y-%m-%d-%H-%M')}))
      system(*%W(#{Gitlab.config.git.bin_path} -C #{repo_path} push origin master))
    end

    def random(max = nil)
      if max
        1 + rand(max)
      else
        rand
      end
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

    task commits: :environment do
      generator = Geo::RandomCommitGenerator.new
      generator.generate(Project.first)
    end
  end
end
