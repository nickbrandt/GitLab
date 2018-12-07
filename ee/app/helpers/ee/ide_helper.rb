# frozen_string_literal: true

module EE
  module IdeHelper
    extend ::Gitlab::Utils::Override

    override :ide_data
    def ide_data
      super.merge({
        "ee-web-terminal-svg-path" => image_path('illustrations/web-ide_promotion.svg'),
        "ee-ci-yaml-help-path" => help_page_path('ci/yaml/README.md'),
        "ee-ci-runners-help-path" => help_page_path('ci/runners/README.md'),
        "ee-web-terminal-help-path" => help_page_path('user/project/web_ide/index.md', anchor: 'client-side-evaluation')
      })
    end
  end
end

::IdeHelper.prepend(::EE::IdeHelper)
