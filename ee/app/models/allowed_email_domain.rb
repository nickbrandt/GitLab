# frozen_string_literal: true

class AllowedEmailDomain < ApplicationRecord
  belongs_to :group, class_name: 'Group', foreign_key: :namespace_id
end
