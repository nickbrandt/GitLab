namespace :minio do
  namespace :install do
    desc "Minio | Install or upgrade the release version of minio"
    task :release_version, [:dir] => :gitlab_environment do |t, args|
      warn_user_is_not_gitlab

      unless args.dir.present?
        abort %(Please specify the directory where you want to install minio:\n  rake "minio:install[/home/git/minio]")
      end

      args.with_defaults(repo: 'https://github.com/minio/minio.git')

      checkout_or_clone_version(version: 'release', repo: args.repo, target_dir: args.dir, clone_opts: %w[--depth 1])

      _, status = Gitlab::Popen.popen(%w[which gmake])
      command = status == 0 ? 'gmake' : 'make'

      Dir.chdir(args.dir) do
        run_command!([command])
      end
    end
  end
end
