# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::SystemNotes::IncidentService do
  let_it_be(:author) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:noteable) { create(:incident, project: project) }
  let_it_be(:issuable_severity) { create(:issuable_severity, issue: noteable, severity: :medium) }

  describe '#change_incident_severity' do
    subject(:change_severity) { described_class.new(noteable: noteable, project: project, author: author).change_incident_severity }

    it_behaves_like 'a system note' do
      let(:action) { 'severity' }
    end

    IssuableSeverity.severities.keys.each do |severity|
      context "with #{severity} severity" do
        before do
          issuable_severity.update!(severity: severity)
        end

        it 'has the appropriate message' do
          severity_label = IssuableSeverity::SEVERITY_LABELS.fetch(severity.to_sym)

          expect(change_severity.note).to eq("changed the severity to **#{severity_label}**")
        end
      end
    end
  end
end
