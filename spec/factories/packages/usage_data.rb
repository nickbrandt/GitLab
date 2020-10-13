# frozen_string_literal: true

FactoryBot.define do
  factory :package_usage_data, class: 'Gitlab::UsageData' do
    skip_create # non-model factories (i.e. without #save)

    initialize_with do
      project_1 = create(:project, packages: [create(:package)] )
      project_2 = create(:project, packages: [create(:package)] )

      token = create(:deploy_token)
      Packages::Event.event_types.keys.each do |event_type|
        Packages::Event.event_scopes.keys.each do |event_scope|
          create(:package_event, event_type: event_type, originator_type: :user, originator: project_1.owner.id, event_scope: event_scope)
          create(:package_event, event_type: event_type, originator_type: :user, originator: project_2.owner.id, event_scope: event_scope)
          create(:package_event, event_type: event_type, originator_type: :deploy_token, originator: token.id, event_scope: event_scope)
          create(:package_event, event_type: event_type, originator_type: :guest, event_scope: event_scope)
        end
      end
    end
  end
end
