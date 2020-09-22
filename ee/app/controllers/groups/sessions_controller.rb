# frozen_string_literal: true

class SessionsController < Devise::SessionsController

  def destroy
    super
    # ActiveSession.destroy_with_namespace_id(current_user, self.id)
  end

end
