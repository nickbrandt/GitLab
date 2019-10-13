# frozen_string_literal: true

module EE
  module Gitlab
    module GlRepository
      module RepoType
        def design?
          self == DESIGN
        end
      end
    end
  end
end
