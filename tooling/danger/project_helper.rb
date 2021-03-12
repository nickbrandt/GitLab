# frozen_string_literal: true

module Tooling
  module Danger
    module ProjectHelper
      LOCAL_RULES ||= %w[
        changes_size
        commit_messages
        database
        documentation
        duplicate_yarn_dependencies
        eslint
        karma
        pajamas
        pipeline
        prettier
        product_intelligence
        utility_css
      ].freeze

      CI_ONLY_RULES ||= %w[
        ce_ee_vue_templates
        changelog
        ci_templates
        metadata
        feature_flag
        roulette
        sidekiq_queues
        specialization_labels
        specs
      ].freeze

      MESSAGE_PREFIX = '==>'.freeze

      # First-match win, so be sure to put more specific regex at the top...
      CATEGORIES = {
        [%r{usage_data\.rb}, %r{^(\+|-).*\s+(count|distinct_count|estimate_batch_distinct_count)\(.*\)(.*)$}] => [:database, :backend],

        %r{\A(ee/)?config/feature_flags/} => :feature_flag,

        %r{\A(ee/)?(changelogs/unreleased)(-ee)?/} => :changelog,

        %r{\Adoc/.*(\.(md|png|gif|jpg))\z} => :docs,
        %r{\A(CONTRIBUTING|LICENSE|MAINTENANCE|PHILOSOPHY|PROCESS|README)(\.md)?\z} => :docs,
        %r{\Adata/whats_new/} => :docs,

        %r{\A(ee/)?app/(assets|views)/} => :frontend,
        %r{\A(ee/)?public/} => :frontend,
        %r{\A(ee/)?spec/(javascripts|frontend)/} => :frontend,
        %r{\A(ee/)?vendor/assets/} => :frontend,
        %r{\A(ee/)?scripts/frontend/} => :frontend,
        %r{(\A|/)(
          \.babelrc |
          \.eslintignore |
          \.eslintrc(\.yml)? |
          \.nvmrc |
          \.prettierignore |
          \.prettierrc |
          \.stylelintrc |
          \.haml-lint.yml |
          \.haml-lint_todo.yml |
          babel\.config\.js |
          jest\.config\.js |
          package\.json |
          yarn\.lock |
          config/.+\.js
        )\z}x => :frontend,

        %r{(\A|/)(
          \.gitlab/ci/frontend\.gitlab-ci\.yml
        )\z}x => %i[frontend engineering_productivity],

        %r{\A(ee/)?db/(geo/)?(migrate|post_migrate)/} => [:database, :migration],
        %r{\A(ee/)?db/(?!fixtures)[^/]+} => :database,
        %r{\A(ee/)?lib/gitlab/(database|background_migration|sql|github_import)(/|\.rb)} => :database,
        %r{\A(app/models/project_authorization|app/services/users/refresh_authorized_projects_service)(/|\.rb)} => :database,
        %r{\A(ee/)?app/finders/} => :database,
        %r{\Arubocop/cop/migration(/|\.rb)} => :database,

        %r{\A(\.gitlab-ci\.yml\z|\.gitlab\/ci)} => :engineering_productivity,
        %r{\A\.codeclimate\.yml\z} => :engineering_productivity,
        %r{\Alefthook.yml\z} => :engineering_productivity,
        %r{\A\.editorconfig\z} => :engineering_productivity,
        %r{Dangerfile\z} => :engineering_productivity,
        %r{\A(ee/)?(danger/|tooling/danger/)} => :engineering_productivity,
        %r{\A(ee/)?scripts/} => :engineering_productivity,
        %r{\Atooling/} => :engineering_productivity,
        %r{(CODEOWNERS)} => :engineering_productivity,
        %r{(tests.yml)} => :engineering_productivity,

        %r{\Alib/gitlab/ci/templates} => :ci_template,

        %r{\A(ee/)?spec/features/} => :test,
        %r{\A(ee/)?spec/support/shared_examples/features/} => :test,
        %r{\A(ee/)?spec/support/shared_contexts/features/} => :test,
        %r{\A(ee/)?spec/support/helpers/features/} => :test,

        %r{\A(ee/)?app/(?!assets|views)[^/]+} => :backend,
        %r{\A(ee/)?(bin|config|generator_templates|lib|rubocop)/} => :backend,
        %r{\A(ee/)?spec/} => :backend,
        %r{\A(ee/)?vendor/} => :backend,
        %r{\A(Gemfile|Gemfile.lock|Rakefile)\z} => :backend,
        %r{\A[A-Z_]+_VERSION\z} => :backend,
        %r{\A\.rubocop((_manual)?_todo)?\.yml\z} => :backend,
        %r{\Afile_hooks/} => :backend,

        %r{\A(ee/)?qa/} => :qa,

        # Files that don't fit into any category are marked with :none
        %r{\A(ee/)?changelogs/} => :none,
        %r{\Alocale/gitlab\.pot\z} => :none,

        # GraphQL auto generated doc files and schema
        %r{\Adoc/api/graphql/reference/} => :backend,

        # Fallbacks in case the above patterns miss anything
        %r{\.rb\z} => :backend,
        %r{(
          \.(md|txt)\z |
          \.markdownlint\.json
        )}x => :none, # To reinstate roulette for documentation, set to `:docs`.
        %r{\.js\z} => :frontend
      }.freeze

      def changes_by_category
        helper.changes_by_category(CATEGORIES)
      end

      def changes
        helper.changes(CATEGORIES)
      end

      def categories_for_file(file)
        helper.categories_for_file(file, CATEGORIES)
      end

      def local_warning_message
        "#{MESSAGE_PREFIX} Only the following Danger rules can be run locally: #{LOCAL_RULES.join(', ')}"
      end
      module_function :local_warning_message # rubocop:disable Style/AccessModifierDeclarations

      def success_message
        "#{MESSAGE_PREFIX} No Danger rule violations!"
      end
      module_function :success_message # rubocop:disable Style/AccessModifierDeclarations

      def rule_names
        helper.ci? ? LOCAL_RULES | CI_ONLY_RULES : LOCAL_RULES
      end

      def all_ee_changes
        all_changed_files.grep(%r{\Aee/})
      end

      def project_name
        ee? ? 'gitlab' : 'gitlab-foss'
      end

      def missing_database_labels(current_mr_labels)
        labels = if has_database_scoped_labels?(current_mr_labels)
                   ['database']
                 else
                   ['database', 'database::review pending']
                 end

        labels - current_mr_labels
      end

      private

      def ee?
        # Support former project name for `dev` and support local Danger run
        %w[gitlab gitlab-ee].include?(ENV['CI_PROJECT_NAME']) || Dir.exist?(File.expand_path('../../../ee', __dir__))
      end

      def has_database_scoped_labels?(current_mr_labels)
        current_mr_labels.any? { |label| label.start_with?('database::') }
      end
    end
  end
end
