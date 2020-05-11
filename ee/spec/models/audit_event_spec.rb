# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvent, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:user).with_foreign_key('author_id') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:author_id) }
    it { is_expected.to validate_presence_of(:entity_id) }
    it { is_expected.to validate_presence_of(:entity_type) }
  end

  describe '.by_entity' do
    let_it_be(:project_event_1) { create(:project_audit_event) }
    let_it_be(:project_event_2) { create(:project_audit_event) }
    let_it_be(:user_event) { create(:user_audit_event) }

    let(:entity_type) { 'Project' }
    let(:entity_id) { project_event_1.entity_id }

    subject(:event) { described_class.by_entity(entity_type, entity_id) }

    it 'returns the correct audit events' do
      expect(event).to contain_exactly(project_event_1)
    end
  end

  describe '.order_by' do
    let_it_be(:event_1) { create(:audit_event) }
    let_it_be(:event_2) { create(:audit_event) }
    let_it_be(:event_3) { create(:audit_event) }

    subject(:event) { described_class.order_by(method) }

    context 'when sort by created_at in ascending order' do
      let(:method) { 'created_asc' }

      it 'sorts results by id in ascending order' do
        expect(event).to eq([event_1, event_2, event_3])
      end
    end

    context 'when it is default' do
      let(:method) { nil }

      it 'sorts results by id in descending order' do
        expect(event).to eq([event_3, event_2, event_1])
      end
    end
  end

  describe '#author_name' do
    context 'when user exists' do
      let(:user) { create(:user, name: 'John Doe') }

      subject(:event) { described_class.new(user: user) }

      it 'returns user name' do
        expect(event.author_name).to eq 'John Doe'
      end
    end

    context 'when user does not exist anymore' do
      subject(:event) { described_class.new(author_id: non_existing_record_id) }

      context 'when details contains author_name' do
        it 'returns author_name' do
          subject.details = { author_name: 'John Doe' }

          expect(event.author_name).to eq 'John Doe'
        end
      end

      context 'when details does not contains author_name' do
        it 'returns nil' do
          subject.details = {}

          expect(subject.author_name).to eq nil
        end
      end
    end

    context 'when authored by an unauthenticated user' do
      subject(:event) { described_class.new(author_id: -1) }

      it 'returns `An unauthenticated user`' do
        expect(subject.author_name).to eq('An unauthenticated user')
      end
    end
  end

  describe '#entity' do
    context 'when entity exists' do
      let(:user) { create(:user, name: 'John Doe') }

      subject(:event) { described_class.new(entity_id: user.id, entity_type: user.class.name) }

      it 'returns the entity object' do
        expect(event.entity).to eq user
      end
    end

    context 'when entity does not exist' do
      subject(:event) { described_class.new(entity_id: non_existing_record_id, entity_type: 'User') }

      it 'returns a NullEntity' do
        expect(event.entity).to be_a(Gitlab::Audit::NullEntity)
      end
    end
  end

  describe '#present' do
    it 'returns a presenter' do
      expect(subject.present).to be_an_instance_of(AuditEventPresenter)
    end
  end

  describe '#formatted_details' do
    subject(:event) { create(:group_audit_event, details: { change: 'membership_lock', from: false, to: true, ip_address: '127.0.0.1' })}

    it 'converts value of `to` and `from` in `details` to string' do
      expect(event.formatted_details[:to]).to eq('true')
      expect(event.formatted_details[:from]).to eq('false')
    end
  end
end
