# frozen_string_literal: true

FactoryBot.define do
  factory :experiment_subject do
    experiment
    variant { :control }
    subject { association :user }
  end
end
