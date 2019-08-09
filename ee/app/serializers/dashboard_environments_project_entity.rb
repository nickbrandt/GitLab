# frozen_string_literal: true

class DashboardEnvironmentsProjectEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :name
  expose :avatar_url
  expose :web_url

  expose :remove_path do |project_object|
    remove_operations_project_path(project_id: project_object.id)
  end

  expose :namespace, using: API::Entities::NamespaceBasic
end
