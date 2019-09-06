# frozen_string_literal: true

module QA
  module EE
    module Resource
      module Board
        class BaseBoard < QA::Resource::Base
          attribute :id
          attribute :name

          def resource_web_url(resource)
            super
          rescue ResourceURLMissingError
            # this particular resource does not expose a web_url property
          end

          def api_post_body
            {
              name: name
            }
          end
        end
      end
    end
  end
end
