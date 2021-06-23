# frozen_string_literal: true

class GroupLabel < Label
  belongs_to :group

  validates :group, presence: true

  alias_attribute :subject, :group

  def subject_foreign_key
    'group_id'
  end

  def self.for_group(group)
    where(group: group).where(project_id: nil)
  end
end
