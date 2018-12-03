# frozen_string_literal: true
require './spec/support/sidekiq'

Sidekiq::Testing.inline! do
  Gitlab::Seeder.quiet do
    user = User.first
    group_path = 'foo'
    project_path = 'bar'
    full_path = "#{group_path}/#{project_path}"
    package_name = "@#{full_path}"

    group = Group.find_by(path: group_path)

    unless group
      group = Group.new(
        name: group_path,
        path: group_path
      )
      group.description = FFaker::Lorem.sentence
      group.save

      group.add_owner(user)
    end

    project = Project.find_by_full_path(full_path)

    unless project
      params = {
        namespace_id: group.id,
        name: project_path,
        description: FFaker::Lorem.sentence,
        visibility_level: Gitlab::VisibilityLevel::PRIVATE,
        skip_disk_validation: true
      }

      project = Projects::CreateService.new(user, params).execute
    end

    (1..10).each do |patch|
      version = "1.0.#{patch}"

      params = {
        name:  package_name,
        versions: {
          version => {
            dist: {
              shasum: 'f572d396fae9206628714fb2ce00f72e94f2258f'
            }
          }
        },
        '_attachments' => {
          "#{package_name}-#{version}.tgz" => {
            'data' => 'aGVsbG8K',
            'length' => 8
          }
        }
      }

      ::Packages::CreateNpmPackageService
        .new(project, user, params).execute

      print '.'
    end
  end
end
