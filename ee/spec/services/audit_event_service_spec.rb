# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEventService do
  let(:project) { create(:project) }
  let(:user) { create(:user, current_sign_in_ip: '192.168.68.104') }
  let(:project_member) { create(:project_member, user: user, expires_at: 1.day.from_now) }

  let(:details) { { action: :destroy } }
  let(:service) { described_class.new(user, project, details) }

  describe '#for_member' do
    it 'generates event' do
      event = service.for_member(project_member).security_event
      expect(event[:details][:target_details]).to eq(user.name)
    end

    it 'handles deleted users' do
      expect(project_member).to receive(:user).and_return(nil)

      event = service.for_member(project_member).security_event
      expect(event[:details][:target_details]).to eq('Deleted User')
    end

    context 'user access expiry' do
      let(:service) { described_class.new(nil, project, { action: :expired }) }

      it 'generates a system event' do
        event = service.for_member(project_member).security_event

        expect(event[:details][:remove]).to eq('user_access')
        expect(event[:details][:system_event]).to be_truthy
        expect(event[:details][:reason]).to include('access expired on')
      end
    end

    context 'updating membership' do
      let(:service) do
        described_class.new(user, project, {
          action: :update,
          old_access_level: 'Reporter',
          old_expiry: Date.today
        })
      end

      it 'records the change in expiry date' do
        event = service.for_member(project_member).security_event

        expect(event[:details][:change]).to eq('access_level')
        expect(event[:details][:expiry_from]).to eq(Date.today)
        expect(event[:details][:expiry_to]).to eq(1.day.from_now.to_date)
      end
    end

    context 'admin audit log licensed' do
      before do
        stub_licensed_features(admin_audit_log: true)
      end

      it 'has the entity full path' do
        event = service.for_member(project_member).security_event

        expect(event[:details][:entity_path]).to eq(project.full_path)
      end

      it 'has the IP address' do
        event = service.for_member(project_member).security_event

        expect(event[:details][:ip_address]).to eq(user.current_sign_in_ip)
      end
    end

    context 'admin audit log unlicensed' do
      before do
        stub_licensed_features(admin_audit_log: false)
      end

      it 'does not have the entity full path' do
        event = service.for_member(project_member).security_event

        expect(event[:details]).not_to have_key(:entity_path)
      end

      it 'does not have the ip_address' do
        event = service.for_member(project_member).security_event

        expect(event[:details]).not_to have_key(:ip_address)
      end
    end
  end

  describe '#security_event' do
    context 'unlicensed' do
      before do
        disable_license_audit_features
      end

      it 'does not create an event' do
        expect(SecurityEvent).not_to receive(:create)

        expect { service.security_event }.not_to change(SecurityEvent, :count)
      end
    end

    context 'licensed' do
      it 'creates an event' do
        expect { service.security_event }.to change(SecurityEvent, :count).by(1)
      end

      context 'on a read-only instance' do
        before do
          allow(Gitlab::Database).to receive(:read_only?).and_return(true)
        end

        it 'does not create an event' do
          expect { service.security_event }.not_to change(SecurityEvent, :count)
        end
      end
    end

    context 'admin audit log licensed' do
      before do
        stub_licensed_features(admin_audit_log: true)
      end

      context 'for an unauthenticated user' do
        let(:details) { { ip_address: '10.11.12.13' } }
        let(:user) { Gitlab::Audit::UnauthenticatedAuthor.new }

        it 'defaults to the IP address in the details hash' do
          event = service.security_event

          expect(event[:details][:ip_address]).to eq('10.11.12.13')
        end
      end

      context 'for an authenticated user' do
        it 'has the user IP address' do
          event = service.security_event

          expect(event[:details][:ip_address]).to eq(user.current_sign_in_ip)
        end
      end

      context 'for an impersonated user' do
        let(:impersonator) { build(:user, name: 'Donald Duck', current_sign_in_ip: '192.168.88.88') }
        let(:user) { build(:user, impersonator: impersonator) }

        it 'has the impersonator IP address' do
          event = service.security_event

          expect(event[:details][:ip_address]).to eq('192.168.88.88')
        end

        it 'has the impersonator name' do
          event = service.security_event

          expect(event[:details][:impersonated_by]).to eq('Donald Duck')
        end
      end
    end
  end

  describe '#enabled?' do
    using RSpec::Parameterized::TableSyntax

    where(:admin_audit_log, :audit_events, :extended_audit_events, :result) do
      true  | false | false | true
      false | true  | false | true
      false | false | true  | true
      false | false | false | false
    end

    with_them do
      before do
        stub_licensed_features(
          admin_audit_log: admin_audit_log,
          audit_events: audit_events,
          extended_audit_events: extended_audit_events
        )
      end

      it 'returns the correct result when feature is available' do
        expect(service.enabled?).to eq(result)
      end
    end
  end

  describe '#entity_audit_events_enabled?' do
    context 'entity is a project' do
      let(:service) { described_class.new(user, project, { action: :destroy }) }

      it 'returns false when project is unlicensed' do
        stub_licensed_features(audit_events: false)

        expect(service.entity_audit_events_enabled?).to be_falsy
      end

      it 'returns true when project is licensed' do
        stub_licensed_features(audit_events: true)

        expect(service.entity_audit_events_enabled?).to be_truthy
      end
    end

    context 'entity is a group' do
      let(:group) { create(:group) }
      let(:service) { described_class.new(user, group, { action: :destroy }) }

      it 'returns false when group is unlicensed' do
        stub_licensed_features(audit_events: false)

        expect(service.entity_audit_events_enabled?).to be_falsey
      end

      it 'returns true when group is licensed' do
        stub_licensed_features(audit_events: true)

        expect(service.entity_audit_events_enabled?).to be_truthy
      end
    end

    context 'entity is a user' do
      let(:service) { described_class.new(user, user, { action: :destroy }) }

      it 'returns false when unlicensed' do
        stub_licensed_features(audit_events: false, admin_audit_log: false)

        expect(service.audit_events_enabled?).to be_falsey
      end

      it 'returns true when licensed with extended events' do
        stub_licensed_features(extended_audit_events: true)

        expect(service.audit_events_enabled?).to be_truthy
      end
    end

    context 'auth event' do
      let(:service) { described_class.new(user, user, { with: 'auth' }) }

      it 'returns true when unlicensed' do
        stub_licensed_features(audit_events: false, admin_audit_log: false)

        expect(service.audit_events_enabled?).to be_truthy
      end
    end
  end

  describe '#for_failed_login' do
    let(:author_name) { 'testuser' }
    let(:ip_address) { '127.0.0.1' }
    let(:service) { described_class.new(author_name, nil, ip_address: ip_address) }
    let(:event) { service.for_failed_login.unauth_security_event }

    before do
      stub_licensed_features(extended_audit_events: true)
    end

    it 'has the right type' do
      expect(event.entity_type).to eq('User')
    end

    it 'has the right author' do
      expect(event.details[:author_name]).to eq(author_name)
    end

    it 'has the right target_details' do
      expect(event.details[:target_details]).to eq(author_name)
    end

    it 'has the right auth method for OAUTH' do
      oauth_service = described_class.new(author_name, nil, ip_address: ip_address, with: 'ldap')
      event = oauth_service.for_failed_login.unauth_security_event

      expect(event.details[:failed_login]).to eq('LDAP')
    end

    context 'admin audit log licensed' do
      before do
        stub_licensed_features(extended_audit_events: true, admin_audit_log: true)
      end

      it 'has the right IP address' do
        expect(event.details[:ip_address]).to eq(ip_address)
      end
    end

    context 'admin audit log unlicensed' do
      before do
        stub_licensed_features(extended_audit_events: true, admin_audit_log: false)
      end

      it 'does not have the ip_address' do
        expect(event.details).not_to have_key(:ip_address)
      end
    end
  end

  describe '#for_user' do
    let(:author_name) { 'Administrator' }
    let(:current_user) { User.new(name: author_name) }
    let(:target_user_full_path) { 'ejohn' }
    let(:user) { instance_spy(User, full_path: target_user_full_path) }
    let(:custom_message) { 'Some strange event has occurred' }
    let(:ip_address) { '127.0.0.1' }
    let(:options) { { action: action, custom_message: custom_message, ip_address: ip_address } }

    subject(:service) { described_class.new(current_user, user, options).for_user }

    context 'with destroy action' do
      let(:action) { :destroy }

      it 'sets the details attribute' do
        expect(service.instance_variable_get(:@details)).to eq(
          remove: 'user',
          author_name: author_name,
          target_id: target_user_full_path,
          target_type: 'User',
          target_details: target_user_full_path
        )
      end
    end

    context 'with create action' do
      let(:action) { :create }

      it 'sets the details attribute' do
        expect(service.instance_variable_get(:@details)).to eq(
          add: 'user',
          author_name: author_name,
          target_id: target_user_full_path,
          target_type: 'User',
          target_details: target_user_full_path
        )
      end
    end

    context 'with custom action' do
      let(:action) { :custom }

      it 'sets the details attribute' do
        expect(service.instance_variable_get(:@details)).to eq(
          custom_message: custom_message,
          author_name: author_name,
          target_id: target_user_full_path,
          target_type: 'User',
          target_details: target_user_full_path,
          ip_address: ip_address
        )
      end
    end
  end

  describe '#for_changes' do
    let(:author_name) { 'Administrator' }
    let(:current_user) { User.new(name: author_name) }
    let(:changed_model) { ApprovalProjectRule.new(id: 6, name: 'Security') }
    let(:options) { { as: 'required approvers', from: 3, to: 4 } }

    subject(:service) { described_class.new(current_user, project, options).for_changes(changed_model) }

    it 'sets the details attribute' do
      expect(service.instance_variable_get(:@details)).to eq(
        change: 'required approvers',
        from: 3,
        to: 4,
        author_name: author_name,
        target_id: 6,
        target_type: 'ApprovalProjectRule',
        target_details: 'Security'
      )
    end
  end

  describe 'license' do
    let(:event) { service.for_project.security_event }

    before do
      disable_license_audit_features
    end

    describe 'has the audit_admin feature' do
      before do
        stub_licensed_features(admin_audit_log: true)
      end

      it 'logs an audit event' do
        expect { event }.to change(AuditEvent, :count).by(1)
      end

      it 'has the entity_path' do
        expect(event.details[:entity_path]).to eq(project.full_path)
      end

      it 'has the user IP address' do
        expect(event.details[:ip_address]).to eq(user.current_sign_in_ip)
      end
    end

    describe 'has the extended_audit_events feature' do
      before do
        stub_licensed_features(extended_audit_events: true)
      end

      it 'logs an audit event' do
        expect { event }.to change(AuditEvent, :count).by(1)
      end

      it 'does not have the entity_path' do
        expect(event.details).not_to have_key(:entity_path)
      end

      it 'does not have the ip_address' do
        expect(event.details).not_to have_key(:ip_address)
      end
    end

    describe 'entity has the audit_events feature' do
      before do
        stub_licensed_features(audit_events: true)
      end

      it 'logs an audit event' do
        expect { event }.to change(AuditEvent, :count).by(1)
      end

      it 'does not have the entity_path' do
        expect(event.details).not_to have_key(:entity_path)
      end

      it 'does not have the ip_address' do
        expect(event.details).not_to have_key(:ip_address)
      end
    end

    describe 'does not have any audit event feature' do
      it 'does not log the audit event' do
        expect { event }.not_to change(AuditEvent, :count)
      end
    end
  end

  def disable_license_audit_features
    stub_licensed_features(
      admin_audit_log: false,
      audit_events: false,
      extended_audit_events: false
    )
  end
end
