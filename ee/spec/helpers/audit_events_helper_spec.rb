# frozen_string_literal: true

require 'spec_helper'

describe AuditEventsHelper do
  describe '#human_text' do
    let(:target_type) { 'User' }
    let(:details) do
      {
        author_name: 'John Doe',
        target_id: 1,
        target_type: target_type,
        target_details: 'Michael'
      }
    end

    subject { human_text(details) }

    context 'when message consist of hash keys' do
      subject { human_text({ remove: 'user_access' }.merge(details))}

      it 'ignores keys that start with start with author_, or target_' do
        expect(subject).to eq 'Remove <strong>user access</strong>    '
      end
    end

    context 'when details contain custom message' do
      let(:custom_message) { 'Custom message <strong>with tags</strong>' }

      subject { human_text( { custom_message: custom_message }.merge(details)) }

      it 'returns custom message' do
        expect(subject).to eq(custom_message)
      end
    end
  end

  describe '#select_keys' do
    it 'returns empty string if key starts with author_' do
      expect(select_keys('author_name', 'John Doe')).to eq ''
    end

    it 'returns empty string if key starts with target_' do
      expect(select_keys('target_name', 'John Doe')).to eq ''
    end

    it 'returns empty string if key is ip_address and the value is blank' do
      expect(select_keys('ip_address', nil)).to eq ''
    end

    it 'returns formatted text if key is ip_address and the value is not blank' do
      expect(select_keys('ip_address', '127.0.0.1')).to eq 'ip_address <strong>127.0.0.1</strong>'
    end

    it 'returns formatted text if key does not start with author_, or target_' do
      expect(select_keys('remove', 'user_access')).to eq 'remove <strong>user_access</strong>'
    end
  end
end
