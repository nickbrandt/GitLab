# frozen_string_literal: true

FactoryBot.define do
  factory :work_item_type, class: 'WorkItem::Type' do
    group

    name { generate(:work_item_type_name) }
    icon_name { 'issue' }
    kind { Issue.issue_types['issue'] }

    trait :bug do
      kind { Issue.issue_types['issue'] }
      name { 'Bug' }
      icon_name { 'bug' }
    end

    trait :feature do
      kind { Issue.issue_types['issue'] }
      name { 'Feature' }
      icon_name { 'feature' }
    end

    trait :incident do
      kind { Issue.issue_types['incident'] }
      icon_name { 'incident' }
    end

    trait :test_case do
      kind { Issue.issue_types['test_case'] }
      icon_name { 'test_case' }
    end
  end
end
