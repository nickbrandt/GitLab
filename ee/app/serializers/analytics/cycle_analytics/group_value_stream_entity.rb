# frozen_string_literal: true

module Analytics
  class GroupValueStreamEntity < Grape::Entity
    expose :name
    expose :id

    private

    def id
      object.id || object.name # use the name `default` if the record is not persisted
    end
  end
end
