# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::Auditor do
  let(:name) { 'play_with_project_settings' }
  let(:author) { build_stubbed(:user) }
  let(:scope) { build_stubbed(:group) }
  let(:target) { build_stubbed(:project) }
  let(:context) { { name: name, author: author, scope: scope, target: target } }
  let(:add_message) { 'Added an interesting field from project Gotham' }
  let(:remove_message) { 'Removed an interesting field from project Gotham' }
  let(:operation) do
    proc do
      ::Gitlab::Audit::EventQueue.push(add_message)
      ::Gitlab::Audit::EventQueue.push(remove_message)
    end
  end

  let(:logger) { instance_spy(Gitlab::AuditJsonLogger) }

  subject(:auditor) { described_class }

  describe '.audit' do
    context 'when recording multiple events', :request_store do
      let(:audit!) { auditor.audit(context, &operation) }

      it 'interacts with the event queue in correct order', :aggregate_failures do
        allow(Gitlab::Audit::EventQueue).to receive(:begin!).and_call_original
        allow(Gitlab::Audit::EventQueue).to receive(:end!).and_call_original

        audit!

        expect(Gitlab::Audit::EventQueue).to have_received(:begin!).ordered
        expect(Gitlab::Audit::EventQueue).to have_received(:end!).ordered
      end

      it 'bulk-inserts audit events to database' do
        allow(AuditEvent).to receive(:bulk_insert!)

        audit!

        expect(AuditEvent).to have_received(:bulk_insert!)
      end

      it 'records audit events in correct order', :aggregate_failures do
        expect { audit! }.to change(AuditEvent, :count).by(2)

        event_messages = AuditEvent.order(:id).map { |event| event.details[:custom_message] }

        expect(event_messages).to eq([add_message, remove_message])
      end

      it 'logs audit events to database', :aggregate_failures do
        audit!

        audit_event = AuditEvent.last

        expect(audit_event.author_id).to eq(author.id)
        expect(audit_event.entity_id).to eq(scope.id)
        expect(audit_event.entity_type).to eq(scope.class.name)
        expect(audit_event.details[:target_id]).to eq(target.id)
        expect(audit_event.details[:target_type]).to eq(target.class.name)
      end

      it 'logs audit events to file' do
        expect(::Gitlab::AuditJsonLogger).to receive(:build).and_return(logger)

        audit!

        expect(logger).to have_received(:info).exactly(2).times.with(
          hash_including(
            'author_id' => author.id,
            'author_name' => author.name,
            'entity_id' => scope.id,
            'entity_type' => scope.class.name,
            'details' => kind_of(Hash)
          )
        )
      end
    end

    context 'when recording single event' do
      let(:audit!) { auditor.audit(context) }
      let(:context) do
        {
          name: name, author: author, scope: scope, target: target,
          message: 'Project has been deleted'
        }
      end

      it 'logs audit event to database', :aggregate_failures do
        expect { audit! }.to change(AuditEvent, :count).by(1)

        audit_event = AuditEvent.last

        expect(audit_event.author_id).to eq(author.id)
        expect(audit_event.entity_id).to eq(scope.id)
        expect(audit_event.entity_type).to eq(scope.class.name)
        expect(audit_event.details[:target_id]).to eq(target.id)
        expect(audit_event.details[:target_type]).to eq(target.class.name)
        expect(audit_event.details[:custom_message]).to eq('Project has been deleted')
      end

      it 'logs audit events to file' do
        expect(::Gitlab::AuditJsonLogger).to receive(:build).and_return(logger)

        audit!

        expect(logger).to have_received(:info).once.with(
          hash_including(
            'author_id' => author.id,
            'author_name' => author.name,
            'entity_id' => scope.id,
            'entity_type' => scope.class.name,
            'details' => kind_of(Hash)
          )
        )
      end
    end

    context 'when audit events are invalid' do
      before do
        allow(AuditEvent).to receive(:bulk_insert!).and_raise(ActiveRecord::RecordInvalid)
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
      end

      it 'tracks error' do
        auditor.audit(context, &operation)

        expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(
          kind_of(ActiveRecord::RecordInvalid),
          { audit_operation: name }
        )
      end

      it 'does not throw exception' do
        expect { auditor.audit(context, &operation) }.not_to raise_exception
      end
    end
  end
end
