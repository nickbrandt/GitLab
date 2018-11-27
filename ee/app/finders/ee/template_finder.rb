# frozen_string_literal: true

module EE
  module TemplateFinder
    extend ::Gitlab::Utils::Override

    CUSTOM_TEMPLATES = HashWithIndifferentAccess.new(
      dockerfiles: ::Gitlab::Template::CustomDockerfileTemplate,
      gitignores: ::Gitlab::Template::CustomGitignoreTemplate,
      gitlab_ci_ymls: ::Gitlab::Template::CustomGitlabCiYmlTemplate
    ).freeze

    attr_reader :custom_templates
    private :custom_templates

    def initialize(type, project, *args, &blk)
      super

      finder = CUSTOM_TEMPLATES.fetch(type)
      @custom_templates = ::Gitlab::CustomFileTemplates.new(finder, project)
    end

    override :execute
    def execute
      return super unless custom_templates.enabled?

      if params[:name]
        custom_templates.find(params[:name]) || super
      else
        custom_templates.all + super
      end
    end
  end
end
