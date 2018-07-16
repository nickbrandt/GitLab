FactoryBot.define do
  factory :protected_environment_deploy_access_level, class: ProtectedEnvironment::DeployAccessLevel do
    user nil
    group nil
    protected_environment
    access_level { Gitlab::Access::DEVELOPER }
  end
end
