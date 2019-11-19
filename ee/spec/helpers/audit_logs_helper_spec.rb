# frozen_string_literal: true

require 'spec_helper'

describe AuditLogsHelper do
  using RSpec::Parameterized::TableSyntax

  describe '#audit_entity_type_label' do
    where(:label, :result) do
      nil       | 'All Events'
      'All'     | 'All Events'
      'User'    | 'User Events'
      'Group'   | 'Group Events'
      'Project' | 'Project Events'
    end

    with_them do
      it { expect(audit_entity_type_label(label)).to eq(result) }
    end
  end
end
