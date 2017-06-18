class ApproversEntity < Grape::Entity
  expose :user, using: UserEntity
end
