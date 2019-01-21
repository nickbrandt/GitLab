# frozen_string_literal: true

require 'spec_helper'

describe SmartcardController, type: :request do
  include LdapHelpers

  let(:certificate_headers) { { 'X-SSL-CLIENT-CERTIFICATE': 'certificate' } }
  let(:openssl_certificate_store) { instance_double(OpenSSL::X509::Store) }
  let(:audit_event_service) { instance_double(AuditEventService) }

  shared_examples 'a client certificate authentication' do |auth_method|
    context 'with smartcard_auth enabled' do
      it 'allows sign in' do
        subject

        expect(request.env['warden']).to be_authenticated
      end

      it 'redirects to root' do
        subject

        expect(response).to redirect_to(root_url)
      end

      it 'logs audit event' do
        expect(AuditEventService).to(
          receive(:new)
            .with(instance_of(User), instance_of(User), with: auth_method)
            .and_return(audit_event_service))
        expect(audit_event_service).to receive_message_chain(:for_authentication, :security_event)

        subject
      end

      context 'user does not exist' do
        context 'signup allowed' do
          it 'creates user' do
            expect { subject }.to change { User.count }.from(0).to(1)
          end
        end

        context 'signup disabled' do
          it 'renders 401' do
            allow(Gitlab::CurrentSettings.current_application_settings).to(
              receive(:allow_signup?).and_return(false))

            subject

            expect(flash[:alert]).to eql('Failed to signing using smartcard authentication')
            expect(response).to redirect_to(new_user_session_path)
            expect(request.env['warden']).not_to be_authenticated
          end
        end
      end
    end

    context 'with smartcard_auth disabled' do
      before do
        allow(Gitlab::Auth::Smartcard).to receive(:enabled?).and_return(false)
      end

      it 'renders 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe '#auth' do
    let(:subject_dn) { '/O=Random Corp Ltd/CN=gitlab-user/emailAddress=gitlab-user@random-corp.org' }
    let(:issuer_dn) { '/O=Random Corp Ltd/CN=Random Corp' }
    let(:certificate_headers) { { 'X-SSL-CLIENT-CERTIFICATE': 'certificate' } }
    let(:openssl_certificate_store) { instance_double(OpenSSL::X509::Store) }
    let(:openssl_certificate) { instance_double(OpenSSL::X509::Certificate, subject: subject_dn, issuer: issuer_dn) }
    let(:audit_event_service) { instance_double(AuditEventService) }

    before do
      allow(Gitlab::Auth::Smartcard).to receive(:enabled?).and_return(true)
      allow(Gitlab::Auth::Smartcard::Certificate).to receive(:store).and_return(openssl_certificate_store)
      allow(openssl_certificate_store).to receive(:verify).and_return(true)
      allow(OpenSSL::X509::Certificate).to receive(:new).and_return(openssl_certificate)
    end

    subject { post '/-/smartcard/auth', params: {}, headers: certificate_headers }

    it_behaves_like 'a client certificate authentication', 'smartcard'

    context 'user already exists' do
      before do
        user = create(:user)
        create(:smartcard_identity, subject: subject_dn, issuer: issuer_dn, user: user)
      end

      it 'finds existing user' do
        expect { subject }.not_to change { User.count }
        expect(request.env['warden']).to be_authenticated
      end
    end

    context 'certificate header formats from NGINX' do
      shared_examples 'valid certificate header' do
        it 'authenticates user' do
          expect(Gitlab::Auth::Smartcard::Certificate).to receive(:new).with(expected_certificate).and_call_original

          subject

          expect(request.env['warden']).to be_authenticated
        end
      end

      let(:expected_certificate) { "-----BEGIN CERTIFICATE-----\nrow\nrow\n-----END CERTIFICATE-----" }

      context 'escaped format' do
        let(:certificate_headers) { { 'X-SSL-CLIENT-CERTIFICATE': '-----BEGIN%20CERTIFICATE-----%0Arow%0Arow%0A-----END%20CERTIFICATE-----' } }

        it_behaves_like 'valid certificate header'
      end

      context 'deprecated format' do
        let(:certificate_headers) { { 'X-SSL-CLIENT-CERTIFICATE': '-----BEGIN CERTIFICATE----- row row -----END CERTIFICATE-----' } }

        it_behaves_like 'valid certificate header'
      end
    end

    context 'missing certificate headers' do
      let(:certificate_headers) { nil }

      it 'renders 401' do
        subject

        expect(response).to have_gitlab_http_status(401)
        expect(request.env['warden']).not_to be_authenticated
      end
    end
  end

  describe '#ldap_auth ' do
    let(:subject_ldap_dn) { 'uid=john doe,ou=people,dc=example,dc=com' }
    let(:issuer_dn) { 'CN=Random Corp,O=Random Corp Ltd,C=US' }
    let(:issuer) { instance_double(OpenSSL::X509::Name, to_s: issuer_dn) }
    let(:serial) { '42' }
    let(:openssl_certificate) do
      instance_double(OpenSSL::X509::Certificate,
                      issuer: issuer, serial: serial)
    end

    let(:ldap_connection) { instance_double(::Net::LDAP) }
    let(:ldap_entry) do
      Net::LDAP::Entry.new.tap do |entry|
        entry['dn'] = subject_ldap_dn
        entry['uid'] = 'john doe'
        entry['cn'] = 'John Doe'
        entry['mail'] = 'john.doe@example.com'
      end
    end
    let(:ldap_user_search_scope) { 'dc=example,dc=com' }
    let(:ldap_search_params) do
      { attributes: array_including('dn', 'cn', 'mail', 'uid', 'userid'),
        base: ldap_user_search_scope,
        filter: Net::LDAP::Filter.ex(
          'userCertificate:certificateExactMatch',
          "{ serialNumber #{serial}, issuer \"#{issuer_dn}\" }") }
    end

    subject do
      post('/-/smartcard/ldap_auth',
           { params: { provider: 'ldapmain' },
             headers: certificate_headers } )
    end

    before do
      allow(Gitlab::Auth::Smartcard).to receive(:enabled?).and_return(true)

      allow(Gitlab::Auth::Smartcard::LDAPCertificate).to(
        receive(:store).and_return(openssl_certificate_store))
      allow(openssl_certificate_store).to receive(:verify).and_return(true)

      allow(OpenSSL::X509::Certificate).to(
        receive(:new).and_return(openssl_certificate))

      allow(Net::LDAP).to receive(:new).and_return(ldap_connection)
      allow(ldap_connection).to(
        receive(:search).with(ldap_search_params).and_return([ldap_entry]))
    end

    it_behaves_like 'a client certificate authentication', 'smartcard_ldap'

    it 'sets correct parameters for LDAP search' do
      expect(ldap_connection).to(
        receive(:search).with(ldap_search_params).and_return([ldap_entry]))

      subject
    end

    context 'user already exists' do
      before do
        user = create(:user)
        create(:identity, { provider: 'ldapmain',
                            extern_uid: subject_ldap_dn,
                            user: user })
      end

      it 'finds existing user' do
        expect { subject }.not_to change { User.count }
        expect(request.env['warden']).to be_authenticated
      end
    end
  end
end
