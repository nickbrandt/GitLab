# frozen_string_literal: true

class DependencyEntity < Grape::Entity
  expose :name, :packager, :version
  expose :location do
    expose :blob_path, :path
  end
end
