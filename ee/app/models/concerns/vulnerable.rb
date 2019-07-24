# frozen_string_literal: true

module Vulnerable
  def latest_vulnerabilities
    Vulnerabilities::Occurrence
      .for_pipelines(all_pipelines.with_vulnerabilities.latest_successful_ids_per_project)
  end

  def latest_vulnerabilities_with_sha
    Vulnerabilities::Occurrence
      .for_pipelines_with_sha(all_pipelines.with_vulnerabilities.latest_successful_ids_per_project)
  end

  def all_vulnerabilities
    Vulnerabilities::Occurrence
      .for_pipelines(all_pipelines.with_vulnerabilities.success)
  end
end
