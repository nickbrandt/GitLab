# frozen_string_literal: true

module ProjectUnauthorized
<<<<<<< HEAD
  prepend EE::ProjectUnauthorized
=======
>>>>>>> upstream/master
  extend ActiveSupport::Concern

  # EE would override this
  def project_unauthorized_proc
    # no-op
  end
end
