require './spec/support/sidekiq_middleware'

Sidekiq::Testing.inline! do
  Gitlab::Seeder.quiet do |seeder|
    Group.all.each do |group|
      seeder.not_mass_generated_users.sample(4).each do |user|
        if group.add_user(user, Gitlab::Access.values.sample).persisted?
          print '.'
        else
          print 'F'
        end
      end
    end

    seeder.not_mass_generated_projects.each do |project|
      seeder.not_mass_generated_users.sample(4).each do |user|
        if project.add_role(user, Gitlab::Access.sym_options.keys.sample)
          print '.'
        else
          print 'F'
        end
      end
    end
  end
end
