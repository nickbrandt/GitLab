# frozen_string_literal: true

FactoryBot.define do
  factory :license_scanning_dependency, class: ::Gitlab::Ci::Reports::LicenseScanning::Dependency do
    initialize_with { new(name, path: path) }

    trait :rails do
      name { 'rails' }
      path { './vendor/bundle/ruby/2.6.0/gems/rails-5.2.3/README.md' }
    end
  end
end
