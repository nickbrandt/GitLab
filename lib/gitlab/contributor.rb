# frozen_string_literal: true

module Gitlab
  class Contributor
    attr_accessor :email, :name, :commits

    def initialize
      @commits = 0
    end
  end
end
