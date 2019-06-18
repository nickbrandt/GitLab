# frozen_string_literal: true

FactoryBot.define do
  factory :design, class: DesignManagement::Design do
    issue
    project { issue.project }
    sequence(:filename) { |n| "homescreen-#{n}.jpg" }

    trait :with_lfs_file do
      with_file

      transient do
        file Gitlab::Git::LfsPointerFile.new('').pointer
      end
    end

    trait :with_file do
      transient do
        versions_count 1
        file File.join(Rails.root, 'spec/fixtures/dk.png')
      end

      after :create do |design, evaluator|
        unless evaluator.versions_count.zero?
          project = design.project
          repository = project.design_repository
          repository.create_if_not_exists

          evaluator.versions_count.times do |i|
            actions = [{
              action: i.zero? ? :create : :update, # First version is :create, successive versions are :update
              file_path: design.full_path,
              content: evaluator.file
            }]

            sha = repository.multi_action(
              project.creator,
              branch_name: 'master',
              message: "Automatically created file #{design.filename}",
              actions: actions
            )

            FactoryBot.create(:design_version, designs: [design], sha: sha)
          end
        end
      end
    end
  end
end
