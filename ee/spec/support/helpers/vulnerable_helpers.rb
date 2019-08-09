# frozen_string_literal: true

module VulnerableHelpers
  class BadVulnerableError < StandardError
    def message
      'The given vulnerable must be either `Project` or `Namespace`'
    end
  end

  def as_vulnerable_project(vulnerable)
    case vulnerable
    when Project
      vulnerable
    when Namespace
      create(:project, namespace: vulnerable)
    else
      raise BadVulnerableError
    end
  end
end
