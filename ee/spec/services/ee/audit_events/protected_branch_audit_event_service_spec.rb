# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::AuditEvents::ProtectedBranchAuditEventService do
  let(:protected_branch) { create(:protected_branch, :no_one_can_push) }
  let(:merge_level) { 'Maintainers' }
  let(:push_level) { 'No one' }
  let(:entity) { protected_branch.project }
  let(:author) { entity.owner }
  let(:logger) { instance_double(Gitlab::AuditJsonLogger) }

  describe '#security_event' do
    shared_examples 'loggable' do |action|
      context "when a protected_branch is #{action}" do
        let(:service) { described_class.new(author, protected_branch, action) }

        it 'creates an event and logs to a file with the provided details' do
          expect(service).to receive(:file_logger).and_return(logger)

          expect(logger).to receive(:info).with(author_id: author.id,
                                                author_name: author.name,
                                                entity_id: entity.id,
                                                entity_type: 'Project',
                                                merge_access_levels: [merge_level],
                                                push_access_levels: [push_level],
                                                target_details: protected_branch.name,
                                                target_id: protected_branch.id,
                                                target_type: 'ProtectedBranch',
                                                action => 'protected_branch')

          expect { service.security_event }.to change(SecurityEvent, :count).by(1)

          security_event = SecurityEvent.last

          expect(security_event.details).to eq(action => 'protected_branch',
                                               author_name: author.name,
                                               target_id:  protected_branch.id,
                                               target_type: 'ProtectedBranch',
                                               target_details: protected_branch.name,
                                               push_access_levels: [push_level],
                                               merge_access_levels: [merge_level])

          expect(security_event.author_id).to eq(author.id)
          expect(security_event.entity_id).to eq(entity.id)
          expect(security_event.entity_type).to eq('Project')
        end
      end
    end

    include_examples 'loggable', :add
    include_examples 'loggable', :remove
    include_examples 'loggable', :update

    context 'when not licensed' do
      let(:service) { described_class.new(author, protected_branch, :add) }

      before do
        stub_licensed_features(audit_events: false,
                               extended_audit_events: false,
                               admin_audit_log: false)
      end

      it "doesn't create an event or log to a file" do
        expect(service).not_to receive(:file_logger)

        expect { service.security_event }.not_to change(SecurityEvent, :count)
      end
    end
  end
end
