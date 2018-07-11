module ProtectedEnvironments
  class BaseService
    attr_reader :project

    def initialize(project)
      @project = project
    end
  end
end
