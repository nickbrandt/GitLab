# frozen_string_literal: true

module EE
  module API
    module Todos
      extend ActiveSupport::Concern

      prepended do
        helpers do
          extend ::Gitlab::Utils::Override

          # rubocop: disable CodeReuse/ActiveRecord
          def epic
            @epic ||= user_group.epics.find_by(iid: params[:epic_iid])
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def authorize_can_read!
            authorize!(:read_epic, epic)
          end

          override :find_todos
          def find_todos
            todos = super

            return todos if ::Feature.enabled?(:design_management_todos_api, default_enabled: true)

            # Exclude Design Todos if the feature is disabled
            todos.where.not(target_type: ::DesignManagement::Design.name) # rubocop: disable CodeReuse/ActiveRecord
          end
        end

        resource :groups, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          desc 'Create a todo on an epic' do
            success ::API::Entities::Todo
          end
          params do
            requires :epic_iid, type: Integer, desc: 'The IID of an epic'
          end
          post ":id/epics/:epic_iid/todo" do
            authorize_can_read!
            todo = ::TodoService.new.mark_todo(epic, current_user).first

            if todo
              present todo, with: ::API::Entities::Todo, current_user: current_user
            else
              not_modified!
            end
          end
        end
      end
    end
  end
end
