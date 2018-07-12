class ProtectedEnvironmentPolicy < BasePolicy

  delegate { @subject.project }

  rule { can?(:admin_project) }.policy do
    enable :create_protected_environment
    enable :update_protected_environment
    enable :destroy_protected_environment
  end
end

