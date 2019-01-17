# frozen_string_literal: true

module EE
  module Import
    module GithubService
      extend ::Gitlab::Utils::Override

      override :extra_project_attrs
      def extra_project_attrs
        super.merge(ci_cd_only: params[:ci_cd_only])
      end
    end
  end
end
