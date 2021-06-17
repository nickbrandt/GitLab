# frozen_string_literal: true

class IncreaseEvidenceBodyLimit < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_text_limit :vulnerability_finding_evidence_requests, :body
    remove_text_limit :vulnerability_finding_evidence_responses, :body

    add_text_limit :vulnerability_finding_evidence_requests, :body, 4096
    add_text_limit :vulnerability_finding_evidence_responses, :body, 4096
  end

  def down
    remove_text_limit :vulnerability_finding_evidence_requests, :body
    remove_text_limit :vulnerability_finding_evidence_responses, :body

    add_text_limit :vulnerability_finding_evidence_requests, :body, 2048
    add_text_limit :vulnerability_finding_evidence_responses, :body, 2048
  end
end
