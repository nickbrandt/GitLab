module API
  class GroupHooks < Grape::API
    include PaginationParams

    before { authenticate! }
    before { authorize_admin_project }

    # TODO: API
  end
end