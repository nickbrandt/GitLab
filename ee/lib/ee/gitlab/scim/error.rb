# frozen_string_literal: true

module EE
  module Gitlab
    module Scim
      class Error < EE::Gitlab::Scim::NotFound
        def status
          409
        end
      end
    end
  end
end
