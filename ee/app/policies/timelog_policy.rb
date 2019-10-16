# frozen_string_literal: true

class TimelogPolicy < BasePolicy
  delegate { @subject.issuable.resource_parent.group }
  delegate { @subject.issuable.resource_parent }
end
