# frozen_string_literal: true

shared_examples 'audit event contains custom message' do
  let(:custom_message) { "Message_with_spaces" }
  let(:details) do
    {
      custom_message: custom_message,
      author_name: 'John Doe',
      target_id: 1,
      target_type: 'User',
      target_details: 'Michael'
    }
  end

  let!(:security_event) do
    ::AuditEventService.new(user, project, details).security_event
  end

  before do
    visit audit_events_url
  end

  it 'user sees this message' do
    expect(page).to have_content('Message_with_spaces')
  end

  context 'when it contains tags' do
    let(:custom_message) { 'Message <strong>with</strong> <i>deleted</i> tags' }

    it 'allows only <strong> tag' do
      message_row = find('.js-audit-action', text: 'Message with deleted tags')

      expect(message_row).to have_selector('strong')
      expect(message_row).to have_no_selector('i')
    end
  end
end
