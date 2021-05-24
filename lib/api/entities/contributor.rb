# frozen_string_literal: true

module API
  module Entities
    class Contributor < Grape::Entity
      expose :name, :email, :commits
    end
  end
end
