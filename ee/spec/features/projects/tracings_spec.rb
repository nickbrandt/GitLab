# frozen_string_literal: true

require 'spec_helper'

describe 'Tracings Content Security Policy' do
  set(:user) { create(:user) }
  let(:project) { create(:project) }

  subject { response_headers['Content-Security-Policy'] }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'when there is no global config' do
    before do
      expect_next_instance_of(Projects::TracingsController) do |controller|
        expect(controller).to receive(:current_content_security_policy)
          .and_return(ActionDispatch::ContentSecurityPolicy.new)
      end
    end

    it 'does not add CSP directives' do
      visit project_tracing_path(project)

      is_expected.to be_blank
    end
  end

  context 'when a global CSP config exists' do
    before do
      csp = ActionDispatch::ContentSecurityPolicy.new do |p|
        p.frame_src :self, 'https://should-get-overwritten.com'
      end

      expect_next_instance_of(Projects::TracingsController) do |controller|
        expect(controller).to receive(:current_content_security_policy).and_return(csp)
      end
    end

    it 'overwrites frame-src' do
      visit project_tracing_path(project)

      is_expected.to eq("frame-src *")
    end
  end
end
