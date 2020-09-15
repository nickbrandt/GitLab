# frozen_string_literal: true

Rails.application.configure do |config|
  Warden::Manager.after_authentication(scope: :user) do |user, auth, opts|
    # Parse gl_scope as a GitLab scoped session.
    if opts.has_key?(:gl_scope)
      ActiveSession.set(user, auth.request, scope: opts[:gl_scope])
    end
  end
end
