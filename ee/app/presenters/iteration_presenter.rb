# frozen_string_literal: true

class IterationPresenter < Gitlab::View::Presenter::Delegated
  presents :iteration

  def iteration_path
    url_builder.build(iteration, only_path: true)
  end

  def iteration_url
    url_builder.build(iteration)
  end
end
