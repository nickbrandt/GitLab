# frozen_string_literal: true

module Gitlab
  class BlamePresenter < Gitlab::View::Presenter::Simple
    presents :blame

    def groups
      @groups ||= blame.groups
    end
  end
end
