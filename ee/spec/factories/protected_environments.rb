FactoryBot.define do
  factory :protected_environment do
    name 'production'
    project

    transient do
      authorize_user_to_deploy nil
      authorize_group_to_deploy nil
    end

    trait :masters_can_deploy do
      after(:build) do |protected_environment|
        protected_environment.deploy_access_levels.new(access_level: Gitlab::Access::MASTER)
      end
    end

    after(:build) do |protected_environment, evaluator|
      if user = evaluator.authorize_user_to_deploy
        protected_environment.deploy_access_levels.new(user: user)
      end

      if group = evaluator.authorize_group_to_deploy
        protected_environment.deploy_access_levels.new(group: group)
      end

      if protected_environment.deploy_access_levels.empty?
        protected_environment.deploy_access_levels.new(user: create(:user))
      end
    end
  end
end
