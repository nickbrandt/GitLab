require './spec/support/sidekiq_middleware'

Gitlab::Seeder.quiet do |seeder|
  admin_user = User.find(1)

  seeder.not_mass_generated_projects.each do |project|
    params = {
      name: 'master'
    }

    ProtectedBranches::CreateService.new(project, admin_user, params).execute
    print '.'
  end
end
