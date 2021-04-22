# frozen_string_literal: true

module Sidebars
  module Projects
    class Panel < ::Sidebars::Panel
      override :configure_menus
      def configure_menus
        set_scope_menu(Sidebars::Projects::Menus::Scope::Menu.new(context))

        add_menu(Sidebars::Projects::Menus::ProjectOverview::Menu.new(context))
        add_menu(Sidebars::Projects::Menus::LearnGitlab::Menu.new(context))
        add_menu(Sidebars::Projects::Menus::Repository::Menu.new(context))
        add_menu(Sidebars::Projects::Menus::Issues::Menu.new(context))
        add_menu(Sidebars::Projects::Menus::ExternalIssueTracker::Menu.new(context))
        add_menu(Sidebars::Projects::Menus::Labels::Menu.new(context))
        add_menu(Sidebars::Projects::Menus::MergeRequests::Menu.new(context))
      end

      override :render_raw_menus_partial
      def render_raw_menus_partial
        'layouts/nav/sidebar/project_menus'
      end

      override :aria_label
      def aria_label
        _('Project navigation')
      end
    end
  end
end

Sidebars::Projects::Panel.prepend_if_ee('EE::Sidebars::Projects::Panel')
