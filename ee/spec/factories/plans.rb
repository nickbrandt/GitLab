# frozen_string_literal: true

# EE-only
FactoryBot.define do
  factory :plan do
    Plan::DEFAULT_PLANS.each do |plan|
      factory :"#{plan}_plan" do
        name { plan }
        title { name.titleize }
        initialize_with { Plan.find_or_create_by(name: plan) }
      end
    end

    Plan::ALL_HOSTED_PLANS.each do |plan|
      factory :"#{plan}_plan" do
        name { plan }
        title { name.titleize }
      end
    end
  end
end
