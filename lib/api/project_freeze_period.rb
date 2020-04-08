# frozen_string_literal: true

module API
  class FreezePeriod < Grape::API
    include PaginationParams

    before do
      authenticate!
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of freeze periods' do
        success Entities::FreezePeriod
      end
      params do
        use :list_params
      end
      get ":id/freeze_periods" do
        authorize! :read_milestone, user_project

        list_milestones_for(user_project)
      end

      desc 'Get a single freeze period' do
        success Entities::FreezePeriod
      end
      params do
        requires :freeze_period_id, type: Integer, desc: 'The ID of a project freeze period'
      end
      get ":id/freeze_periods/:freeze_period_id" do
        authorize! :read_milestone, user_project

        get_milestone_for(user_project)
      end

      desc 'Create a new freeze period' do
        success Entities::FreezePeriod
      end
      params do
        requires :title, type: String, desc: 'The title of the milestone'
        use :optional_params
      end
      post ":id/freeze_periods" do
        authorize! :admin_milestone, user_project

        create_milestone_for(user_project)
      end

      desc 'Update an existing freeze period' do
        success Entities::FreezePeriod
      end
      params do
        use :update_params
      end
      put ":id/milestones/:milestone_id" do
        authorize! :admin_milestone, user_project

        update_milestone_for(user_project)
      end

      desc 'Remove a freeze period'
      delete ":id/milestones/:milestone_id" do
        authorize! :admin_milestone, user_project

        milestone = user_project.milestones.find(params[:milestone_id])
        Milestones::DestroyService.new(user_project, current_user).execute(milestone)

        no_content!
      end
    end
  end
end