module EE
  module NavHelper
    extend ::Gitlab::Utils::Override

    override :show_separator?
    def show_separator?
      super || can?(current_user, :read_operations_dashboard)
    end

    override :page_has_markdown?
    def page_has_markdown?
      super || current_path?('epics#show')
    end
  end
end
