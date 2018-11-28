# frozen_string_literal: true

module API
  class ProjectRemoteMirrors < Grape::API
    before do
      authenticate!
      authorize_admin_project
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Delete a project remote mirror'
      params do
        requires :remote_mirror_id, type: Integer, desc: 'The ID of a project remote mirror'
      end
      delete ":id/remote_mirrors/:remote_mirror_id" do
        remote_mirror = RemoteMirror.find(params[:remote_mirror_id])

        destroy_conditionally!(remote_mirror)
      end
    end
  end
end
