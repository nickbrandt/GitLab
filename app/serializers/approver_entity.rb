class ApproverEntity < Grape::Entity
  expose :user, using: UserEntity
end
