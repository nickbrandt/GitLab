# frozen_string_literal: true

module EE
  module Gitlab
    module Scim
      class NotFound < EE::Gitlab::Scim::Error
        def status
          404
        end
      end
    end
  end
end
