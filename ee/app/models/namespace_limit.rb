# frozen_string_literal: true

class NamespaceLimit < ApplicationRecord
  self.primary_key = :namespace_id

  belongs_to :namespace, inverse_of: :namespace_limit

  def temporary_storage_increase_enabled?
    return false unless ::Feature.enabled?(:temporary_storage_increase, namespace)
    return false if temporary_storage_increase_ends_on.nil?

    temporary_storage_increase_ends_on >= Date.today
  end
end
