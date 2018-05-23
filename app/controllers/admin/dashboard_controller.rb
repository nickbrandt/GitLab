class Admin::DashboardController < Admin::ApplicationController
<<<<<<< HEAD
  prepend ::EE::Admin::DashboardController

=======
>>>>>>> 1d77de4713f49ccacb6e8819bc70321b5950ab28
  include CountHelper

  def index
    @projects = Project.order_id_desc.without_deleted.with_route.limit(10)
    @users = User.order_id_desc.limit(10)
    @groups = Group.order_id_desc.with_route.limit(10)
    @license = License.current
  end
end
