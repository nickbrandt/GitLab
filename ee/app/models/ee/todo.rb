# frozen_string_literal: true

module EE
  module Todo
    extend ::Gitlab::Utils::Override

    override :parent
    def parent
      project || group
    end

    def for_design?
      target_type == DesignManagement::Design.name
    end
  end
end
