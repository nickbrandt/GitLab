# frozen_string_literal: true

FactoryBot.define do
  factory :semver, class: 'Packages::SemVer' do
    initialize_with { new(attributes[:major], attributes[:minor], attributes[:patch], attributes[:prerelease], attributes[:build], prefixed: attributes[:prefixed]) }
    skip_create

    major { 1 }
    minor { 0 }
    patch { 0 }
    prerelease { nil }
    build { nil }
    prefixed { false }
  end
end
