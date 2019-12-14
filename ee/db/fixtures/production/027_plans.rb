# frozen_string_literal: true

Gitlab::Seeder.quiet do
  Plan.create!(name: Plan::DEFAULT, title: Plan::DEFAULT.titleize)
  Plan.create!(name: Plan::FREE, title: Plan::FREE.titleize) if Gitlab.com?
end
