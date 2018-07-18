FactoryBot.define do
  factory :ci_build_environment_failure, class: Ci::Build, parent: :ci_build do
    status 'failed'
    failure_reason 6
  end
end
