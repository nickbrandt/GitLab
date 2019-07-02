# frozen_string_literal: true

FactoryBot.define do
  factory :insight do
    group
    project
  end

  factory :insights_issues_by_team, class: Hash do
    initialize_with do
      {
        Gitlab::Insights::InsightLabel.new('Manage', 'red') => 1,
        Gitlab::Insights::InsightLabel.new('Plan', 'blue') => 3,
        Gitlab::Insights::InsightLabel.new('Create') => 2,
        Gitlab::Insights::InsightLabel.new('undefined', 'gray') => 1
      }.with_indifferent_access
    end
  end

  factory :insights_merge_requests_per_month, class: Hash do
    initialize_with do
      {
        Gitlab::Insights::InsightLabel.new('January 2019') => 1,
        Gitlab::Insights::InsightLabel.new('February 2019') => 2,
        Gitlab::Insights::InsightLabel.new('March 2019') => 3
      }
    end
  end

  factory :insights_issues_by_team_per_month, class: Hash do
    initialize_with do
      {
        Gitlab::Insights::InsightLabel.new('January 2019') => {
          Gitlab::Insights::InsightLabel.new('Manage', 'red') => 1,
          Gitlab::Insights::InsightLabel.new('Plan', 'blue') => 1,
          Gitlab::Insights::InsightLabel.new('Create') => 1,
          Gitlab::Insights::InsightLabel.new('undefined', 'gray') => 0
        }.with_indifferent_access,
        Gitlab::Insights::InsightLabel.new('February 2019') => {
          Gitlab::Insights::InsightLabel.new('Manage', 'red') => 0,
          Gitlab::Insights::InsightLabel.new('Plan', 'blue') => 1,
          Gitlab::Insights::InsightLabel.new('Create') => 0,
          Gitlab::Insights::InsightLabel.new('undefined', 'gray') => 0
        }.with_indifferent_access,
        Gitlab::Insights::InsightLabel.new('March 2019') => {
          Gitlab::Insights::InsightLabel.new('Manage', 'red') => 0,
          Gitlab::Insights::InsightLabel.new('Plan', 'blue') => 1,
          Gitlab::Insights::InsightLabel.new('Create') => 1,
          Gitlab::Insights::InsightLabel.new('undefined', 'gray') => 1
        }.with_indifferent_access
      }
    end
  end
end
