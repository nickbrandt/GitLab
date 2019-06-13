# frozen_string_literal: true

module Types
  class EpicType < BaseObject
    graphql_name 'Epic'

    authorize :read_epic

    expose_permissions Types::PermissionTypes::Epic

    present_using EpicPresenter

    implements(Types::Notes::NoteableType)

    field :id, GraphQL::ID_TYPE, null: false
    field :iid, GraphQL::ID_TYPE, null: false
    field :title, GraphQL::STRING_TYPE, null: true
    field :description, GraphQL::STRING_TYPE, null: true
    field :state, EpicStateEnum, null: false

    field :group, GroupType,
          null: false,
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(Group, obj.group_id).find }
    field :parent, EpicType,
          null: true,
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(Epic, obj.parent_id).find }
    field :author, Types::UserType,
          null: false,
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(User, obj.author_id).find }

    field :start_date, Types::TimeType, null: true
    field :start_date_is_fixed, GraphQL::BOOLEAN_TYPE, null: true, method: :start_date_is_fixed?, authorize: :admin_epic
    field :start_date_fixed, Types::TimeType, null: true, authorize: :admin_epic
    field :start_date_from_milestones, Types::TimeType, null: true, authorize: :admin_epic

    field :due_date, Types::TimeType, null: true
    field :due_date_is_fixed, GraphQL::BOOLEAN_TYPE, null: true, method: :due_date_is_fixed?, authorize: :admin_epic
    field :due_date_fixed, Types::TimeType, null: true, authorize: :admin_epic
    field :due_date_from_milestones, Types::TimeType, null: true, authorize: :admin_epic

    field :closed_at, Types::TimeType, null: true
    field :created_at, Types::TimeType, null: true
    field :updated_at, Types::TimeType, null: true

    field :children,
          ::Types::EpicType.connection_type,
          null: true,
          resolver: ::Resolvers::EpicResolver

    field :has_children, GraphQL::BOOLEAN_TYPE, null: false, method: :has_children?
    field :has_issues, GraphQL::BOOLEAN_TYPE, null: false, method: :has_issues?

    field :web_path, GraphQL::STRING_TYPE, null: false, method: :group_epic_path
    field :web_url, GraphQL::STRING_TYPE, null: false, method: :group_epic_url
    field :relation_path, GraphQL::STRING_TYPE, null: true, method: :group_epic_link_path
    field :reference, GraphQL::STRING_TYPE, null: false, method: :epic_reference do
      argument :full, GraphQL::BOOLEAN_TYPE, required: false, default_value: false
    end

    field :issues,
          Types::EpicIssueType.connection_type,
          null: true,
          resolver: Resolvers::EpicIssuesResolver
  end
end
