# frozen_string_literal: true

module EE
  module TodosHelper
    extend ::Gitlab::Utils::Override

    override :todo_target_path
    def todo_target_path(todo)
      return todos_design_path(todo) if todo.for_design?

      super
    end

    override :todo_target_type_name
    def todo_target_type_name(todo)
      return _('design') if todo.for_design?

      super
    end

    override :todo_types_options
    def todo_types_options
      super + ee_todo_types_options
    end

    private

    def todos_design_path(todo)
      design = todo.target
      path_options = todo_target_path_options(todo).merge(
        vueroute: design.filename
      )

      designs_project_issue_path(
        todo.resource_parent,
        design.issue,
        path_options
      )
    end

    def ee_todo_types_options
      [
        { id: 'Epic', text: 'Epic' },
        { id: 'DesignManagement::Design', text: 'Design' }
      ]
    end
  end
end
