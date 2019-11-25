# frozen_string_literal: true

shared_examples 'forbids actions on vulnerability in case of disabled features' do
  context 'when "first-class vulnerabilities" feature is disabled' do
    before do
      stub_feature_flags(first_class_vulnerabilities: false)
    end

    it 'responds with "not found"' do
      subject

      expect(response).to have_gitlab_http_status(404)
    end
  end

  context 'when security dashboard feature is not available' do
    before do
      stub_licensed_features(security_dashboard: false)
    end

    it 'responds with 403 Forbidden' do
      subject

      expect(response).to have_gitlab_http_status(403)
    end
  end
end

shared_examples 'responds with "not found" for an unknown vulnerability ID' do
  let(:vulnerability_id) { 0 }

  it do
    subject

    expect(response).to have_gitlab_http_status(404)
  end
end
