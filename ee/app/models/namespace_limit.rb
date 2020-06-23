# frozen_string_literal: true

class NamespaceLimit < ApplicationRecord
  self.primary_key = :namespace_id

  belongs_to :namespace, inverse_of: :namespace_limit
end
