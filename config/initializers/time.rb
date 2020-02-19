# frozen_string_literal: true

class Time
  def log_format
    self.utc.iso8601(3)
  end
end
