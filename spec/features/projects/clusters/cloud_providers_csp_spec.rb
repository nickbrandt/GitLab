# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create cluster cloud providers CSP' do
  include GoogleApi::CloudPlatformHelpers

  subject { response_headers['Content-Security-Policy'] }

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    gitlab_sign_in(user)
    allow(Projects::ClustersController).to receive(:STATUS_POLLING_INTERVAL) { 100 }
  end

  context 'when accessing create new k8s cluster page' do
    context 'when no global CSP config exists' do
      before do
        expect_next_instance_of(Projects::ClustersController) do |controller|
          expect(controller).to receive(:current_content_security_policy)
            .and_return(ActionDispatch::ContentSecurityPolicy.new)
        end
      end

      it 'does not add CSP directives' do
        visit project_clusters_path(project)

        is_expected.to be_blank
      end
    end

    context 'when a global CSP config exists' do
      let_it_be(:cdn_url) { 'https://some-cdn.test' }
      let_it_be(:amazon_aws_api_url) { 'https://*.amazonaws.com' }
      let_it_be(:google_apis_url) { 'https://apis.google.com https://*.googleapis.com' }

      before do
        csp = ActionDispatch::ContentSecurityPolicy.new do |p|
          p.connect_src :self, cdn_url
        end

        expect_next_instance_of(Projects::ClustersController) do |controller|
          expect(controller).to receive(:current_content_security_policy).and_return(csp)
        end
      end

      it 'appends amazon and google apis url to the CSP connect-src policy' do
        visit project_clusters_path(project)

        is_expected.to eql("connect-src 'self' #{cdn_url} #{amazon_aws_api_url} #{google_apis_url}")
      end
    end
  end
end
