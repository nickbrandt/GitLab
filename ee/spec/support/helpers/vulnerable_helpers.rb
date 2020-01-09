# frozen_string_literal: true

module VulnerableHelpers
  class BadVulnerableError < StandardError
    def message
      'The given vulnerable must be either `Project`, `Namespace`, or `ApplicationInstance`'
    end
  end

  def as_vulnerable_project(vulnerable)
    case vulnerable
    when Project
      vulnerable
    when Namespace
      create(:project, namespace: vulnerable)
    when ApplicationInstance
      create(:project)
    else
      raise BadVulnerableError
    end
  end

  def as_external_vulnerable_project(vulnerable)
    case vulnerable
    when Project
      create(:project)
    when Namespace
      create(:project)
    when ApplicationInstance
      nil
    else
      raise BadVulnerableError
    end
  end
end
