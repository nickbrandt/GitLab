# frozen_string_literal: true

module Gitlab
  class BlamePresenter < Gitlab::View::Presenter::Simple
    include ActionView::Helpers::UrlHelper
    include AvatarsHelper

    presents :blame

    def initialize(subject, **attributes)
      super

      precalculate_data_by_commit!
    end

    def groups
      @groups ||= blame.groups
    end

    def author_avatar_by_commit(commit_id)
      @author_avatars[commit_id]
    end

    private

    def precalculate_data_by_commit!
      @author_avatars = {}

      groups.each do |blame_group|
        commit = blame_group[:commit]
        @author_avatars[commit.id] ||= author_avatar(commit, size: 36, has_tooltip: false)
      end
    end
  end
end
