# frozen_string_literal: true

FactoryBot.define do
  factory :design, class: DesignManagement::Design do
    issue { create(:issue) }
    project { issue.project }
    sequence(:filename) { |n| "homescreen-#{n}.jpg" }

    transient do
      author { issue.author }
    end

    create_versions = ->(design, evaluator, commit_version) do
      unless evaluator.versions_count.zero?
        project = design.project
        issue = design.issue
        repository = project.design_repository
        repository.create_if_not_exists
        dv_table_name = DesignManagement::Action.table_name
        updates = [0, evaluator.versions_count - (evaluator.deleted ? 2 : 1)].max

        run_action = ->(action) do
          sha = commit_version[action]
          version = DesignManagement::Version.new(sha: sha, issue: issue, author: evaluator.author)
          version.save(validate: false) # We need it to have an ID, validate later
          Gitlab::Database.bulk_insert(dv_table_name, [action.row_attrs(version)])
        end

        # always a creation
        run_action[DesignManagement::DesignAction.new(design, :create, evaluator.file)]

        # 0 or more updates
        updates.times do
          run_action[DesignManagement::DesignAction.new(design, :update, evaluator.file)]
        end

        # and maybe a deletion
        run_action[DesignManagement::DesignAction.new(design, :delete)] if evaluator.deleted
      end

      design.clear_version_cache
    end

    trait :with_lfs_file do
      with_file

      transient do
        file { Gitlab::Git::LfsPointerFile.new('').pointer }
      end
    end

    # Use this trait if you want versions in a particular history, but don't
    # want to pay for gitlay calls.
    trait :with_versions do
      transient do
        deleted { false }
        versions_count { 1 }
        sequence(:file) { |n| "some-file-content-#{n}" }
      end

      after :create do |design, evaluator|
        counter = (1..).lazy

        # Just produce a SHA by hashing the action and a monotonic counter
        commit_version = ->(action) do
          Digest::SHA1.hexdigest("#{action.gitaly_action}.#{counter.next}")
        end

        create_versions[design, evaluator, commit_version]
      end
    end

    # Use this trait if you want your designs to be as true-to-life as possible,
    # with correctly made commits in the repository and files that can be retrieved.
    trait :with_file do
      transient do
        deleted { false }
        versions_count { 1 }
        file { File.join(Rails.root, 'spec/fixtures/dk.png') }
      end

      after :create do |design, evaluator|
        project = design.project
        repository = project.design_repository

        commit_version = ->(action) do
          repository.multi_action(
            evaluator.author,
            branch_name: 'master',
            message: "#{action.action} for #{design.filename}",
            actions: [action.gitaly_action]
          )
        end

        create_versions[design, evaluator, commit_version]
      end
    end
  end
end
