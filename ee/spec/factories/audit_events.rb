# frozen_string_literal: true

FactoryBot.define do
  factory :audit_event, class: 'SecurityEvent', aliases: [:user_audit_event] do
    user

    entity_type { 'User' }
    entity_id   { user.id }
    details do
      {
        change: 'email address',
        from: 'admin@gitlab.com',
        to: 'maintainer@gitlab.com',
        author_name: user.name,
        target_id: user.id,
        target_type: 'User',
        target_details: user.name,
        ip_address: '127.0.0.1',
        entity_path: user.username
      }
    end

    trait :project_event do
      entity_type { 'Project' }
      entity_id   { create(:project).id }
      details do
        {
          add: 'user_access',
          as: 'Developer',
          author_name: user.name,
          target_id: user.id,
          target_type: 'User',
          target_details: user.name,
          ip_address: '127.0.0.1',
          entity_path: 'gitlab.org/gitlab-ce'
        }
      end
    end

    trait :group_event do
      entity_type { 'Group' }
      entity_id   { create(:group).id }
      details do
        {
          change: 'project_creation_level',
          from: nil,
          to: 'Developers + Maintainers',
          author_name: 'Administrator',
          target_id: 1,
          target_type: 'Group',
          target_details: "gitlab-org",
          ip_address: '127.0.0.1',
          entity_path: "gitlab-org"
        }
      end
    end

    factory :project_audit_event, traits: [:project_event]
    factory :group_audit_event, traits: [:group_event]
  end
end
