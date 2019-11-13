# frozen_string_literal: true

# EE-only
FactoryBot.define do
  factory :plan do
    factory :default_plan do
      name { Plan::DEFAULT }
      title { name.titleize }
    end

    EE::Namespace::PLANS.each do |plan|
      factory :"#{plan}_plan" do
        name { plan }
        title { name.titleize }
      end
    end
  end
end
