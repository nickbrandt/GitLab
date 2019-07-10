# frozen_string_literal: true

class EpicPolicy < BasePolicy
  delegate { @subject.group }

  condition(:maintainer) { @subject.group.has_maintainer?(@user) }

  rule { can?(:read_epic) }.policy do
    enable :read_epic_iid
    enable :read_note
  end

  rule { can?(:read_epic) & ~anonymous }.policy do
    enable :create_note
  end

  rule { can?(:create_note) }.enable :award_emoji

  rule { maintainer }.enable :admin_note
end
