# frozen_string_literal: true

module EE
  module Gitlab
    module Patch
      module DrawRoute
        extend ::Gitlab::Utils::Override

        override :draw_ee
        def draw_ee(routes_name)
          draw_route(route_path("ee/config/routes/#{routes_name}.rb"))
        end
      end
    end
  end
end
