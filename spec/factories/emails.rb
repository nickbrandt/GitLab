# frozen_string_literal: true

FactoryBot.define do
  factory :email do
    user
    email { generate(:email_alias) }

    trait(:confirmed) { confirmed_at { Time.now } }
    trait(:unconfirmed) { confirmed_at { nil } }
    trait(:skip_validate) { to_create {|instance| instance.save(validate: false) } }
  end
end
