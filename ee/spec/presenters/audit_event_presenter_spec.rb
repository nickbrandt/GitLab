# frozen_string_literal: true

require 'spec_helper'

describe AuditEventPresenter do
  include Gitlab::Routing.url_helpers

  let(:details) do
    {
      author_name: 'author',
      ip_address: '127.0.0.1',
      target_details: 'target name',
      entity_path: 'path',
      from: 'a',
      to: 'b'
    }
  end

  let(:audit_event) { create(:audit_event, details: details) }

  subject(:presenter) do
    described_class.new(audit_event)
  end

  context 'exposes the author' do
    it 'gets the event author name' do
      expect(presenter.author_name).to eq(audit_event.user.name)
    end

    context 'event authored by a user that exists' do
      it 'returns a url' do
        expect(presenter.author_url).to eq(url_for(user_path(audit_event.user)))
      end
    end

    context 'event authored by a user that no longer exists' do
      let(:user) { create(:user) }
      let(:audit_event) { create(:audit_event, user: user, details: details) }

      before do
        user.destroy
        audit_event.reload
      end

      context 'when `author_name` is not included in the details' do
        let(:details) do
          {
            author_name: nil,
            ip_address: '127.0.0.1',
            target_details: 'target name',
            entity_path: 'path',
            from: 'a',
            to: 'b'
          }
        end

        it 'does not return a url' do
          expect(presenter.author_url).to be_blank
        end
      end

      context 'when `author_name` is included in the details' do
        it 'shows the author name as provided in the details' do
          expect(presenter.author_name).to eq('author')
        end
      end
    end

    context 'event authored by an unauthenticated user' do
      before do
        audit_event.author_id = -1
      end

      context 'when `author_name` is not included in details' do
        let(:details) do
          {
            author_name: nil,
            ip_address: '127.0.0.1',
            target_details: 'target name',
            entity_path: 'path',
            from: 'a',
            to: 'b'
          }
        end

        it 'shows `An unauthenticated user` as the author name' do
          expect(presenter.author_name).to eq('An unauthenticated user')
        end
      end

      context 'when `author_name` is included in details' do
        it 'shows the author name as provided in the details' do
          expect(presenter.author_name).to eq('author')
        end
      end
    end
  end

  it 'exposes the target' do
    expect(presenter.target).to eq(details[:target_details])
  end

  it 'exposes the ip address' do
    expect(presenter.ip_address).to eq(details[:ip_address])
  end

  context 'exposes the object' do
    it 'returns the object path if it exists' do
      expect(presenter.object).to eq(details[:entity_path])
    end

    it 'returns the stored name if it has been deleted' do
      audit_event.entity_id = nil

      expect(presenter.object).to be_blank
    end

    it 'returns the object url if it exists' do
      expect(presenter.object_url).to eq(url_for(audit_event.entity))
    end

    it 'returns no object url if it has been deleted' do
      audit_event.entity_id = nil

      expect(presenter.object_url).to be_blank
    end
  end

  it 'exposes the date' do
    expect(presenter.date).to eq(audit_event.created_at.to_s(:db))
  end

  it 'exposes the action' do
    expect(presenter.action).to eq('Changed author from a to b')
  end
end
