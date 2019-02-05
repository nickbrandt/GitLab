# frozen_string_literal: true

shared_examples 'a certificate store' do
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
        expect { subject }.to(
          raise_error(Gitlab::Auth::Smartcard::Certificate::InvalidCAFilePath))
      end
    end

    context 'smartcard ca_file is not a valid certificate' do
      it 'raises error' do
        expect(File).to(
          receive(:read).with('ca_file').and_return('invalid certificate'))
        expect { subject }.to(
          raise_error(Gitlab::Auth::Smartcard::Certificate::InvalidCertificate))
      end
    end
  end

  def clear_store
    described_class.remove_instance_variable(:@store)
  rescue NameError
    # raised if @store was not set; ignore
  end
end

shared_examples 'a valid certificate is required' do
  context 'invalid certificate' do
    it 'returns nil' do
      allow(openssl_certificate_store).to receive(:verify).and_return(false)

      expect(subject).to be_nil
    end
  end

  context 'incorrect certificate' do
    it 'returns nil' do
      allow(OpenSSL::X509::Certificate).to receive(:new).and_call_original

      expect(subject).to be_nil
    end
  end
end
