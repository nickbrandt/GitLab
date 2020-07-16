# frozen_string_literal: true

FactoryBot.define do
  factory :dast_site_profile do
    name { FFaker::Product.product_name }

    before(:create) do |dast_site_profile|
      project = FactoryBot.create(:project)
      dast_site = FactoryBot.create(:dast_site, project: project)

      dast_site_profile.project = project
      dast_site_profile.dast_site = dast_site
    end
  end
end
