# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Auth::Smartcard::Certificate do
  let(:subject_dn) { '/O=Random Corp Ltd/CN=gitlab-user/emailAddress=gitlab-user@random-corp.org' }
  let(:issuer_dn) { '/O=Random Corp Ltd/CN=Random Corp' }
  let(:certificate_header) { 'certificate' }
  let(:openssl_certificate_store) { instance_double(OpenSSL::X509::Store) }
  let(:openssl_certificate) { instance_double(OpenSSL::X509::Certificate, subject: subject_dn, issuer: issuer_dn) }
  let(:user_build_service) { instance_double(Users::BuildService) }

  before do
    allow(described_class).to receive(:store).and_return(openssl_certificate_store)
    allow(OpenSSL::X509::Certificate).to receive(:new).and_return(openssl_certificate)
    allow(openssl_certificate_store).to receive(:verify).and_return(true)
  end

  shared_examples 'a new smartcard identity' do
    it 'creates smartcard identity' do
      expect { subject }.to change { SmartcardIdentity.count }.from(0).to(1)

      identity = SmartcardIdentity.first
      expect(identity.subject).to eql(subject_dn)
      expect(identity.issuer).to eql(issuer_dn)
    end
  end

  shared_examples 'an existing user' do
    it 'finds existing user' do
      expect(subject).to eql(user)
    end

    it 'does not create new user' do
      expect { subject }.not_to change { User.count }
    end
  end

  describe '#find_or_create_user' do
    subject { described_class.new(certificate_header).find_or_create_user }

    context 'user and smartcard identity already exist' do
      let(:user) { create(:user) }

      before do
        create(:smartcard_identity, subject: subject_dn, issuer: issuer_dn, user: user)
      end

      it_behaves_like 'an existing user'
    end

    context 'user exists but smartcard identity does not' do
      let!(:user) { create(:user, email: 'gitlab-user@random-corp.org') }

      it_behaves_like 'an existing user'

      it_behaves_like 'a new smartcard identity'

      it 'associates the new smartcard identity with the user' do
        subject

        expect(SmartcardIdentity.first.user).to eql(user)
      end
    end

    context 'user and smartcard identity do not exist' do
      let(:user) { create(:user) }

      before do
        allow(Gitlab::Auth::Smartcard).to receive(:enabled?).and_return(true)
      end

      it 'creates user' do
        expect { subject }.to change { User.count }.from(0).to(1)
        expect(User.first.username).to eql('gitlab-user')
        expect(User.first.email).to eql('gitlab-user@random-corp.org')
      end

      it_behaves_like 'a new smartcard identity'

      it 'calls Users::BuildService with correct params' do
        user_params = { name: 'gitlab-user',
                        username: 'gitlab-user',
                        email: 'gitlab-user@random-corp.org',
                        password_automatically_set: true,
                        certificate_subject:  subject_dn,
                        certificate_issuer: issuer_dn,
                        skip_confirmation: true }
        expect(Users::BuildService).to(
          receive(:new)
            .with(nil, hash_including(user_params))
            .and_return(user_build_service))
        expect(user_build_service).to(
          receive(:execute).with(skip_authorization: true).and_return(user))

        subject
      end

      context 'username generation' do
        context 'uses CN from certificate' do
          let(:subject_dn) { '/CN=Gitlab User/emailAddress=gitlab-user@random-corp.org' }

          it 'creates user with correct username' do
            subject

            expect(User.first.username).to eql('GitlabUser')
          end
        end

        context 'avoids conflicting namespaces' do
          let(:subject_dn) { '/CN=Gitlab User/emailAddress=gitlab-user@random-corp.org' }
          let!(:existing_user) { create(:user, username: 'GitlabUser') }

          it 'creates user with correct usnername' do
            expect { subject }.to change { User.count }.from(1).to(2)
            expect(User.last.username).to eql('GitlabUser1')
          end
        end
      end
    end

    context 'invalid certificate' do
      before do
        allow(openssl_certificate_store).to receive(:verify).and_return(false)
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'incorrect certificate' do
      before do
        allow(OpenSSL::X509::Certificate).to receive(:new).and_call_original
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '.store' do
    before do
      allow(Gitlab.config.smartcard).to receive(:ca_file).and_return('ca_file')
      allow(described_class).to receive(:store).and_call_original
      allow(OpenSSL::X509::Certificate).to receive(:new).and_call_original
      clear_store
    end
    after do
      clear_store
    end

    subject { described_class.store }

    context 'file does not exist' do
      it 'raises error' do
        expect { subject }.to raise_error(Gitlab::Auth::Smartcard::Certificate::InvalidCAFilePath)
      end
    end

    context 'smartcard.ca_file is not a valid certificate' do
      it 'raises error' do
        expect(File).to receive(:read).with('ca_file').and_return('invalid certificate')
        expect { subject }.to raise_error(Gitlab::Auth::Smartcard::Certificate::InvalidCertificate)
      end
    end
  end

  def clear_store
    described_class.remove_instance_variable(:@store)
  rescue NameError
    # raised if @store was not set; ignore
  end
end
