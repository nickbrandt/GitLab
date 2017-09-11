class Admin::LogsController < Admin::ApplicationController
<<<<<<< HEAD
  prepend EE::Admin::LogsController

=======
>>>>>>> ce/10-0-stable
  before_action :loggers

  def show
  end

  private

  def loggers
    @loggers ||= [
      Gitlab::AppLogger,
      Gitlab::GitLogger,
      Gitlab::EnvironmentLogger,
      Gitlab::SidekiqLogger,
      Gitlab::RepositoryCheckLogger
    ]
  end
end
