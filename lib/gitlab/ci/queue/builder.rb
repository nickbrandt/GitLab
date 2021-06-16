# frozen_string_literal: true

module Gitlab
  module Ci
    module Queue
      class Builder < SimpleDelegator
        attr_reader :runner

        def initialize(runner)
          @runner = runner

          @strategy = begin
            if ::Feature.enabled?(:ci_pending_builds_queue_source, runner, default_enabled: :yaml)
              PendingBuildsTableStrategy.new(runner)
            else
              BuildsTableStrategy.new(runner)
            end
          end

          super(@strategy)
        end

        ##
        # This is overridden in EE
        #
        def builds_for_shared_runner
          @strategy.builds_for_shared_runner
        end

        # rubocop:disable CodeReuse/ActiveRecord
        def builds_for_group_runner
          # Workaround for weird Rails bug, that makes `runner.groups.to_sql` to return `runner_id = NULL`
          groups = ::Group.joins(:runner_namespaces).merge(runner.runner_namespaces)

          hierarchy_groups = Gitlab::ObjectHierarchy
            .new(groups, options: { use_distinct: ::Feature.enabled?(:use_distinct_in_register_job_object_hierarchy) })
            .base_and_descendants

          projects = Project.where(namespace_id: hierarchy_groups)
            .with_group_runners_enabled
            .with_builds_enabled
            .without_deleted

          relation = @strategy.new_builds.where(project: projects)

          @strategy.order(relation)
        end

        def builds_for_project_runner
          relation = @strategy.new_builds
            .where(project: runner.projects.without_deleted.with_builds_enabled)

          @strategy.order(relation)
        end

        def builds_queued_before(relation, time)
          relation.queued_before(time)
        end

        class BuildsTableStrategy
          attr_reader :runner, :common

          def initialize(runner)
            @runner = runner
          end

          def builds_for_shared_runner
            relation = new_builds
              # don't run projects which have not enabled shared runners and builds
              .joins('INNER JOIN projects ON ci_builds.project_id = projects.id')
              .where(projects: { shared_runners_enabled: true, pending_delete: false })
              .joins('LEFT JOIN project_features ON ci_builds.project_id = project_features.project_id')
              .where('project_features.builds_access_level IS NULL or project_features.builds_access_level > 0')

            if Feature.enabled?(:ci_queueing_disaster_recovery, runner, type: :ops, default_enabled: :yaml)
              # if disaster recovery is enabled, we fallback to FIFO scheduling
              relation.order('ci_builds.id ASC')
            else
              # Implement fair scheduling
              # this returns builds that are ordered by number of running builds
              # we prefer projects that don't use shared runners at all
              relation
                .joins("LEFT JOIN (#{running_builds_for_shared_runners.to_sql}) AS project_builds ON ci_builds.project_id = project_builds.project_id")
                .order(Arel.sql('COALESCE(project_builds.running_builds, 0) ASC'), 'ci_builds.id ASC')
            end
          end

          def builds_matching_tag_ids(relation, ids)
            # pick builds that does not have other tags than runner's one
            relation.matches_tag_ids(ids)
          end

          def builds_with_any_tags(relation)
            # pick builds that have at least one tag
            relation.with_any_tags
          end

          def order(relation)
            relation.order('id ASC')
          end

          def build_ids(relation)
            relation.pluck(:id)
          end

          def new_builds
            if runner.ref_protected?
              all_builds.ref_protected
            else
              all_builds
            end
          end

          private

          def all_builds
            ::Ci::Build.pending.unstarted
          end

          def running_builds_for_shared_runners
            ::Ci::Build.running
              .where(runner: ::Ci::Runner.instance_type)
              .group(:project_id)
              .select(:project_id, 'count(*) AS running_builds')
          end
        end

        class PendingBuildsTableStrategy
          attr_reader :runner

          def initialize(runner)
            @runner = runner
          end

          def builds_for_shared_runner
            relation = new_builds
              # don't run projects which have not enabled shared runners and builds
              .joins('INNER JOIN projects ON ci_pending_builds.project_id = projects.id')
              .where(projects: { shared_runners_enabled: true, pending_delete: false })
              .joins('LEFT JOIN project_features ON ci_pending_builds.project_id = project_features.project_id')
              .where('project_features.builds_access_level IS NULL or project_features.builds_access_level > 0')

            if Feature.enabled?(:ci_queueing_disaster_recovery, runner, type: :ops, default_enabled: :yaml)
              # if disaster recovery is enabled, we fallback to FIFO scheduling
              relation.order('ci_pending_builds.build_id ASC')
            else
              # Implement fair scheduling
              # this returns builds that are ordered by number of running builds
              # we prefer projects that don't use shared runners at all
              relation
                .joins("LEFT JOIN (#{running_builds_for_shared_runners.to_sql}) AS project_builds ON ci_pending_builds.project_id=project_builds.project_id")
                .order(Arel.sql('COALESCE(project_builds.running_builds, 0) ASC'), 'ci_pending_builds.build_id ASC')
            end
          end

          def builds_for_project_runner
            new_builds
              .where(project: runner.projects.without_deleted.with_builds_enabled)
              .order('build_id ASC')
          end

          def builds_for_group_runner
            # Workaround for weird Rails bug, that makes `runner.groups.to_sql` to return `runner_id = NULL`
            groups = ::Group.joins(:runner_namespaces).merge(runner.runner_namespaces)

            hierarchy_groups = Gitlab::ObjectHierarchy
              .new(groups, options: { use_distinct: ::Feature.enabled?(:use_distinct_in_register_job_object_hierarchy) })
              .base_and_descendants

            projects = Project.where(namespace_id: hierarchy_groups)
              .with_group_runners_enabled
              .with_builds_enabled
              .without_deleted

            new_builds.where(project: projects).order('build_id ASC')
          end

          def builds_matching_tag_ids(relation, ids)
            relation.merge(CommitStatus.matches_tag_ids(ids, on: 'ci_pending_builds.build_id'))
          end

          def builds_with_any_tags(relation)
            relation.merge(CommitStatus.with_any_tags(on: 'ci_pending_builds.build_id'))
          end

          def builds_queued_before(relation, time)
            relation.queued_before(time)
          end

          def order(relation)
            relation.order('build_id ASC')
          end

          def build_ids(relation)
            relation.pluck(:build_id)
          end

          def new_builds
            if runner.ref_protected?
              all_builds.ref_protected
            else
              all_builds
            end
          end

          private

          def all_builds
            ::Ci::PendingBuild.all
          end

          def running_builds_for_shared_runners
            ::Ci::RunningBuild
              .where(runner: ::Ci::Runner.instance_type)
              .group(:project_id)
              .select(:project_id, 'count(*) AS running_builds')
          end
          # rubocop:enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end

Gitlab::Ci::Queue::Builder.prepend_mod_with('Gitlab::Ci::Queue::Builder')
