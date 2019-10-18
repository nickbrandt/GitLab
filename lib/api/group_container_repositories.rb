# frozen_string_literal: true

module API
  class GroupContainerRepositories < Grape::API
    include PaginationParams

    before { authorize_read_group_container_images! }

    params do
      requires :id, type: String, desc: "Group's ID or path"
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of all repositories within a group' do
        detail 'This feature was introduced in GitLab 12.2.'
        success Entities::ContainerRegistry::Repository
      end
      params do
        use :pagination
        optional :tags, type: Boolean, default: false, desc: 'Determines if tags should be included'
      end
      get ':id/registry/repositories' do
        repositories = ContainerRepositoriesFinder.new(
          id: user_group.id, container_type: :group
        ).execute

        present paginate(repositories), with: Entities::ContainerRegistry::Repository, tags: params[:tags]
      end

      desc 'Delete repository tags (in bulk) within a group' do
        detail 'This feature was introduced in GitLab 12.6.'
      end
      params do
        requires :name_regex, type: String, desc: 'The tag name regexp to delete, specify .* to delete all'
        optional :keep_n, type: Integer, desc: 'Keep n of latest tags with matching name'
        optional :older_than, type: String, desc: 'Delete older than: 1h, 1d, 1month'
      end
      delete ':id/registry/repositories/tags', requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        authorize_admin_container_image!

        message = 'This request has already been made. You can run this at most once an hour for a given group'
        render_api_error!(message, 400) unless obtain_new_cleanup_container_lease

        repositories = ContainerRepositoriesFinder.new(
          id: user_group.id, container_type: :group
        ).execute

        repositories.each do |repository|
          CleanupContainerRepositoryWorker.perform_async(
            current_user.id, repository.id,
            declared_params.except(:repository_id)
          )
        end

        status :accepted
      end
    end

    helpers do
      def authorize_read_group_container_images!
        authorize! :read_container_image, user_group
      end

      def authorize_admin_container_image!
        authorize! :admin_container_image, user_group
      end

      def obtain_new_cleanup_container_lease
        Gitlab::ExclusiveLease
          .new("container_repository:cleanup_tags:group:#{user_group.id}",
               timeout: 1.hour)
          .try_obtain
      end
    end
  end
end
