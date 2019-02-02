# frozen_string_literal: true

class ApprovalProjectRule < ApplicationRecord
  include ApprovalRuleLike

  belongs_to :project

  # To allow easier duck typing
  scope :regular, -> { all }
  scope :code_owner, -> { none }

  def regular
    true
  end
  alias_method :regular?, :regular

  def code_owner
    false
  end
  alias_method :code_owner?, :code_owner

  def source_rule
    nil
  end
end
