# frozen_string_literal: true

module Gitlab
  class BlamePresenter < Gitlab::View::Presenter::Simple
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TranslationHelper
    include ActionView::Context
    include AvatarsHelper
    include BlameHelper
    include CommitsHelper
    include ApplicationHelper
    include TreeHelper
    include IconsHelper

    presents :blame

    def initialize(subject, **attributes)
      super

      precalculate_data_by_commit!
    end

    def groups
      @groups ||= blame.groups
    end

    def author_avatar_for(commit_id)
      @author_avatars[commit_id]
    end

    def age_map_class_for(commit_id)
      @age_map_classes[commit_id]
    end

    def commit_link_for(commit_id)
      @commit_links[commit_id]
    end

    def commit_author_link_for(commit_id)
      @commit_author_links[commit_id]
    end

    def project_blame_link_for(commit_id)
      @project_blame_links[commit_id]
    end

    def time_ago_tooltip_for(commit_id)
      @time_ago_tooltips[commit_id]
    end

    private

    def precalculate_data_by_commit!
      @author_avatars = {}
      @age_map_classes = {}
      @commit_links = {}
      @commit_author_links = {}
      @project_blame_links = {}
      @time_ago_tooltips = {}

      groups.map { |g| g[:commit] }.uniq.each do |commit|
        @author_avatars[commit.id] ||= author_avatar(commit, size: 36, has_tooltip: false)
        @age_map_classes[commit.id] ||= age_map_class(commit.committed_date, project_duration)
        @commit_links[commit.id] ||= link_to commit.title, project_commit_path(project, commit.id), class: "cdark", title: commit.title
        @commit_author_links[commit.id] ||= commit_author_link(commit, avatar: false)
        @time_ago_tooltips[commit.id] ||= time_ago_with_tooltip(commit.committed_date)
        @project_blame_links[commit.id] ||= project_blame_link(commit)
      end
    end

    def project_blame_link(commit)
      previous_commit_id = commit.parent_id
      return unless previous_commit_id

      link_to project_blame_path(project, tree_join(previous_commit_id, path)),
        title: _('View blame prior to this change'),
        aria: { label: _('View blame prior to this change') },
        data: { toggle: 'tooltip', placement: 'right', container: 'body' } do
          versions_sprite_icon
        end
    end

    def project_duration
      @project_duration ||= age_map_duration(groups, project)
    end

    def versions_sprite_icon
      @versions_sprite_icon ||= sprite_icon('doc-versions', size: 16, css_class: 'doc-versions align-text-bottom')
    end
  end
end
