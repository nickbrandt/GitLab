# frozen_string_literal: true

class LDAPKey < Key
  def can_delete?
    false
  end
end
