# frozen_string_literal: true

module Geo
  class RepositoriesChangedEvent < ApplicationRecord
    include Geo::Model
    include Geo::Eventable

    belongs_to :geo_node

    validates :geo_node, presence: true
  end
end
