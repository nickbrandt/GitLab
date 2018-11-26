# frozen_string_literal: true

module EE::Admin::LogsController
  include ::Gitlab::Utils::StrongMemoize
  extend ::Gitlab::Utils::Override

  override :loggers
  def loggers
    strong_memoize(:loggers) do
      super + [
        Gitlab::GeoLogger
      ]
    end
  end
end
