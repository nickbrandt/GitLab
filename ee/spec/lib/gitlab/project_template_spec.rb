# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ProjectTemplate do
  describe '.all' do
    context 'when `enterprise_templates` feature is not licensed' do
      before do
        stub_licensed_features(enterprise_templates: false)
      end

      it 'does not contain enterprise project templates' do
        expect(described_class.all).not_to include(*enterprise_templates)
      end
    end

    context 'when `enterprise_templates` feature is licensed' do
      before do
        stub_licensed_features(enterprise_templates: true)
      end

      it 'contains enterprise project templates' do
        expect(described_class.all).to include(*enterprise_templates)
      end
    end
  end

  private

  def enterprise_templates
    [
      described_class.new('hipaa_audit_protocol', 'HIPAA Audit Protocol', _('A project containing issues for each audit inquiry in the HIPAA Audit Protocol published by the U.S. Department of Health & Human Services'), 'https://gitlab.com/gitlab-org/project-templates/hipaa-audit-protocol')
    ]
  end
end
