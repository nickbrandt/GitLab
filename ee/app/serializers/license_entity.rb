# frozen_string_literal: true

class LicenseEntity < Grape::Entity
  class ComponentEntity < Grape::Entity
    expose :name
  end

  expose :name
  expose :url
  expose :dependencies, using: ComponentEntity, as: :components
end
