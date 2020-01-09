# frozen_string_literal: true

module Types
  class EpicType < BaseObject
    graphql_name 'Epic'
    description 'Represents an epic.'

    authorize :read_epic

    expose_permissions Types::PermissionTypes::Epic

    present_using EpicPresenter

    implements(Types::Notes::NoteableType)

    field :id, GraphQL::ID_TYPE, null: false,
          description: 'ID of the epic'
    field :iid, GraphQL::ID_TYPE, null: false,
          description: 'Internal ID of the epic'
    field :title, GraphQL::STRING_TYPE, null: true,
          description: 'Title of the epic'
    field :description, GraphQL::STRING_TYPE, null: true,
          description: 'Description of the epic'
    field :state, EpicStateEnum, null: false,
          description: 'State of the epic'

    field :group, GroupType, null: false,
          description: 'Group to which the epic belongs',
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(Group, obj.group_id).find }
    field :parent, EpicType, null: true,
          description: 'Parent epic of the epic',
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(Epic, obj.parent_id).find }
    field :author, Types::UserType, null: false,
          description: 'Author of the epic',
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(User, obj.author_id).find }

    field :start_date, Types::TimeType, null: true,
          description: 'Start date of the epic'
    field :start_date_is_fixed, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if the start date has been manually set',
          method: :start_date_is_fixed?, authorize: :admin_epic
    field :start_date_fixed, Types::TimeType, null: true,
          description: 'Fixed start date of the epic',
          authorize: :admin_epic
    field :start_date_from_milestones, Types::TimeType, null: true,
          description: 'Inherited start date of the epic from milestones',
          authorize: :admin_epic

    field :due_date, Types::TimeType, null: true,
          description: 'Due date of the epic'
    field :due_date_is_fixed, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if the due date has been manually set',
          method: :due_date_is_fixed?, authorize: :admin_epic
    field :due_date_fixed, Types::TimeType, null: true,
          description: 'Fixed due date of the epic',
          authorize: :admin_epic
    field :due_date_from_milestones, Types::TimeType, null: true,
          description: 'Inherited due date of the epic from milestones',
          authorize: :admin_epic

    field :upvotes, GraphQL::INT_TYPE, null: false,
          description: 'Number of upvotes the epic has received'
    field :downvotes, GraphQL::INT_TYPE, null: false,
          description: 'Number of downvotes the epic has received'

    field :closed_at, Types::TimeType, null: true,
          description: "Timestamp of the epic's closure"
    field :created_at, Types::TimeType, null: true,
          description: "Timestamp of the epic's creation"
    field :updated_at, Types::TimeType, null: true,
          description: "Timestamp of the epic's last activity"

    field :children, ::Types::EpicType.connection_type, null: true,
          description: 'Children (sub-epics) of the epic',
          resolver: ::Resolvers::EpicResolver
    field :labels, Types::LabelType.connection_type, null: true,
          description: 'Labels assigned to the epic'

    field :has_children, GraphQL::BOOLEAN_TYPE, null: false,
          description: 'Indicates if the epic has children',
          method: :has_children?
    field :has_issues, GraphQL::BOOLEAN_TYPE, null: false,
          description: 'Indicates if the epic has direct issues',
          method: :has_issues?

    field :web_path, GraphQL::STRING_TYPE, null: false, method: :group_epic_path # rubocop:disable Graphql/Descriptions
    field :web_url, GraphQL::STRING_TYPE, null: false, method: :group_epic_url # rubocop:disable Graphql/Descriptions
    field :relative_position, GraphQL::INT_TYPE, null: true,
          description: 'The relative position of the epic in the epic tree'
    field :relation_path, GraphQL::STRING_TYPE, null: true, method: :group_epic_link_path # rubocop:disable Graphql/Descriptions
    field :reference, GraphQL::STRING_TYPE, null: false, method: :epic_reference do # rubocop:disable Graphql/Descriptions
      argument :full, GraphQL::BOOLEAN_TYPE, required: false, default_value: false # rubocop:disable Graphql/Descriptions
    end
    field :participants, Types::UserType.connection_type, null: true,
          description: 'List of participants for the epic',
          complexity: 5

    field :subscribed, GraphQL::BOOLEAN_TYPE,
      method: :subscribed?,
      null: false,
      complexity: 5,
      description: 'Indicates the currently logged in user is subscribed to the epic'

    field :issues,
          Types::EpicIssueType.connection_type,
          null: true,
          complexity: 2,
          description: 'A list of issues associated with the epic',
          resolver: Resolvers::EpicIssuesResolver

    field :descendant_counts, Types::EpicDescendantCountType, null: true, complexity: 10,
      description: 'Number of open and closed descendant epics and issues',
      resolve: -> (epic, args, ctx) do
        Epics::DescendantCountService.new(epic, ctx[:current_user])
      end
  end
end
