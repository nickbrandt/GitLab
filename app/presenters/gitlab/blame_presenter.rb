# frozen_string_literal: true

module Gitlab
  class BlamePresenter < Gitlab::View::Presenter::Simple
    include ActionView::Helpers::UrlHelper
    include AvatarsHelper
    include BlameHelper

    presents :blame

    def initialize(subject, **attributes)
      super

      precalculate_data_by_commit!
    end

    def groups
      @groups ||= blame.groups
    end

    def author_avatar_for_commit(commit_id)
      @author_avatars[commit_id]
    end

    def age_map_class_for_commit(commit_id)
      @age_map_classes[commit_id]
    end

    private

    def precalculate_data_by_commit!
      @author_avatars = {}
      @age_map_classes = {}

      groups.each do |blame_group|
        commit = blame_group[:commit]
        @author_avatars[commit.id] ||= author_avatar(commit, size: 36, has_tooltip: false)

        @age_map_classes[commit.id] ||= age_map_class(commit.committed_date, project_duration)
      end
    end

    def project_duration
      @project_duration ||= age_map_duration(groups, project)
    end
  end
end
