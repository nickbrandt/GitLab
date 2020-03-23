# frozen_string_literal: true

require 'spec_helper'

describe 'projects/pages/show' do
  include LetsEncryptHelpers

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:domain) { create(:pages_domain, project: project) }
  let(:error_message) do
    "Something went wrong while obtaining Let's Encrypt certificate for #{domain.domain}. "\
    "To retry visit your domain details."
  end

  before do
    allow(project).to receive(:pages_deployed?).and_return(true)
    stub_pages_setting(external_https: true)
    stub_lets_encrypt_settings
    project.add_maintainer(user)

    assign(:project, project)
    allow(view).to receive(:current_user).and_return(user)
    assign(:domains, [domain])
  end

  it "doesn't show auto ssl error warning" do
    render

    expect(rendered).not_to have_content(error_message)
  end

  context "when we failed to obtain Let's Encrypt's certificate" do
    before do
      domain.update!(auto_ssl_failed: true)
    end

    it 'shows auto ssl error warning' do
      render

      expect(rendered).to have_content(error_message)
    end

    it "doesn't show warning if lets_encrypt_error feature flag is disabled" do
      stub_feature_flags(pages_letsencrypt_errors: false)

      render

      expect(rendered).not_to have_content(error_message)
    end

    it "doesn't show warning if Let's Encrypt integration is disabled" do
      allow(::Gitlab::LetsEncrypt).to receive(:enabled?).and_return false

      render

      expect(rendered).not_to have_content(error_message)
    end
  end
end
