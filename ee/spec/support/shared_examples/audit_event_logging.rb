# frozen_string_literal: true

shared_examples_for 'audit event logging' do
  before do
    stub_licensed_features(extended_audit_events: true)
  end

  context 'if operation succeed' do
    it 'logs an audit event if operation succeed' do
      expect { operation }.to change(AuditEvent, :count).by(1)
    end

    it 'logs the project info' do
      @resource = operation

      expect(AuditEvent.last).to have_attributes(attributes)
    end
  end

  it 'does not log audit event if project operation fails' do
    fail_condition!

    expect { operation }.not_to change(AuditEvent, :count)
  end
end

shared_examples_for 'logs the custom audit event' do
  let(:logger) { instance_double(Gitlab::AuditJsonLogger) }

  before do
    stub_licensed_features(audit_events: true)
  end

  it 'creates an event and logs to a file with the provided details' do
    expect(service).to receive(:file_logger).and_return(logger)
    expect(logger).to receive(:info).with(author_id: user.id,
                                          entity_id: entity.id,
                                          entity_type: entity_type,
                                          action: :custom,
                                          ip_address: ip_address,
                                          custom_message: custom_message)

    expect { service.security_event }.to change(SecurityEvent, :count).by(1)
    security_event = SecurityEvent.last

    expect(security_event.details).to eq(custom_message: custom_message,
                                         ip_address: ip_address,
                                         action: :custom)
    expect(security_event.author_id).to eq(user.id)
    expect(security_event.entity_id).to eq(entity.id)
    expect(security_event.entity_type).to eq(entity_type)
  end
end
