# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Keys::CreateService do
  let(:admin_user) { create(:admin)}
  let(:user) { create(:user) }
  let(:params) { attributes_for(:key).merge(user: user) }

  subject { described_class.new(admin_user, params) }

  it 'creates' do
    stub_licensed_features(extended_audit_events: true)

    expect { subject.execute }.to change { SecurityEvent.count }.by(1)
    event = SecurityEvent.last
    expect(event.author_name).to eq(admin_user.name)
    expect(event.entity_id).to eq(user.id)
  end
end
