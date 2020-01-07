# frozen_string_literal: true
class Gitlab::Seeder::Packages
  def initialize(user, project)
    @user = user
    @project = project
  end

  def seed
    5.times do |i|
      package_name = "@#{@project.full_path}"
      version = "1.12.#{i}"

      params = JSON.parse(
        fixture_json
          .gsub('@root/npm-test', package_name)
          .gsub('1.0.1', version))
        .with_indifferent_access

      ::Packages::Npm::CreatePackageService.new(@project, @user, params).execute
    end
  end

  private

  def fixture_json
    File.read(fixture_path)
  end

  def fixture_path
    Rails.root.join('ee', 'spec', 'fixtures', 'npm', 'payload.json')
  end
end

Gitlab::Seeder.quiet do
  Project.not_mass_generated.sample(5).each do |project|
    Gitlab::Seeder::Packages.new(project.owner, project).seed
  end
end
