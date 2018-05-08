class ProjectMirrorEntity < Grape::Entity
<<<<<<< HEAD
  prepend ::EE::ProjectMirrorEntity

=======
>>>>>>> 632244e7ad4a77dc5bf7ef407812b875d20569bb
  expose :id

  expose :remote_mirrors_attributes do |project|
    next [] unless project.remote_mirrors.present?

    project.remote_mirrors.map do |remote|
      remote.as_json(only: %i[id url enabled])
    end
  end
end
