# frozen_string_literal: true

module EE
  module Gitlab
    module Favicon
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        override :development_favicon
        def development_favicon
          'favicon-green.png'
        end
      end
    end
  end
end
