# frozen_string_literal: true

class LicensesFinder
  include Gitlab::Allowable

  def initialize(user, id: nil)
    @user = user
    @id = id
  end

  def execute
    raise Gitlab::Access::AccessDeniedError unless can?(user, :read_licenses)

    items = License.all
    items = by_id(items)

    items.recent
  end

  private

  attr_reader :id, :user

  def by_id(items)
    return items unless id

    items.where(id: id) # rubocop:disable CodeReuse/ActiveRecord
  end
end
