# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::BuildService do
  let(:author) { build_stubbed(:author, current_sign_in_ip: '127.0.0.1') }
  let(:scope) { build_stubbed(:group) }
  let(:target) { build_stubbed(:project) }
  let(:ip_address) { '192.168.8.8' }
  let(:message) { 'Added an interesting field from project Gotham' }

  subject(:service) do
    described_class.new(
      author: author,
      scope: scope,
      target: target,
      message: message
    )
  end

  describe '#execute', :request_store do
    subject(:event) { service.execute }

    before do
      allow(Gitlab::RequestContext.instance).to receive(:client_ip).and_return(ip_address)
    end

    context 'when licensed' do
      before do
        stub_licensed_features(admin_audit_log: true)
      end

      it 'sets correct attributes', :aggregate_failures do
        freeze_time do
          expect(event).to have_attributes(
            author_id: author.id,
            author_name: author.name,
            entity_id: scope.id,
            entity_type: scope.class.name
          )

          expect(event.details).to eq(
            author_name: author.name,
            target_id: target.id,
            target_type: target.class.name,
            target_details: target.name,
            custom_message: message,
            ip_address: ip_address,
            entity_path: scope.full_path
          )

          expect(event.ip_address).to eq(ip_address)
          expect(event.created_at).to eq(DateTime.current)
        end
      end

      context 'when IP address is not provided' do
        let(:ip_address) { nil }

        it 'uses author current_sign_in_ip' do
          expect(event.ip_address).to eq(author.current_sign_in_ip)
        end
      end

      context 'when author is impersonated' do
        let(:impersonator) { build_stubbed(:user, name: 'Agent Donald', current_sign_in_ip: '8.8.8.8') }
        let(:author) { build_stubbed(:author, impersonator: impersonator) }

        it 'sets author to impersonated user', :aggregate_failures do
          expect(event.author_id).to eq(author.id)
          expect(event.author_name).to eq(author.name)
        end

        it 'includes impersonator name in message' do
          expect(event.details[:custom_message])
            .to eq('Added an interesting field from project Gotham (by Agent Donald)')
        end

        context 'when IP address is not provided' do
          let(:ip_address) { nil }

          it 'uses impersonator current_sign_in_ip' do
            expect(event.ip_address).to eq(impersonator.current_sign_in_ip)
          end
        end
      end
    end

    context 'when not licensed' do
      before do
        stub_licensed_features(admin_audit_log: false)
      end

      it 'sets correct attributes', :aggregate_failures do
        freeze_time do
          expect(event).to have_attributes(
            author_id: author.id,
            author_name: author.name,
            entity_id: scope.id,
            entity_type: scope.class.name
          )

          expect(event.details).to eq(
            author_name: author.name,
            target_id: target.id,
            target_type: target.class.name,
            target_details: target.name,
            custom_message: message
          )

          expect(event.ip_address).to be_nil
          expect(event.created_at).to eq(DateTime.current)
        end
      end

      context 'when author is impersonated' do
        let(:impersonator) { build_stubbed(:user, name: 'Agent Donald', current_sign_in_ip: '8.8.8.8') }
        let(:author) { build_stubbed(:author, impersonator: impersonator) }

        it 'does not includes impersonator name in message' do
          expect(event.details[:custom_message])
            .to eq('Added an interesting field from project Gotham')
        end
      end
    end

    context 'when attributes are missing' do
      context 'when author is missing' do
        let(:author) { nil }

        it { expect { service }.to raise_error(described_class::MissingAttributeError) }
      end

      context 'when scope is missing' do
        let(:scope) { nil }

        it { expect { service }.to raise_error(described_class::MissingAttributeError) }
      end

      context 'when target is missing' do
        let(:target) { nil }

        it { expect { service }.to raise_error(described_class::MissingAttributeError) }
      end

      context 'when message is missing' do
        let(:message) { nil }

        it { expect { service }.to raise_error(described_class::MissingAttributeError) }
      end
    end
  end
end
