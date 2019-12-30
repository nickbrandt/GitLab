# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Filter::IssueReferenceFilter do
  include FilterSpecHelper
  include DesignManagementTestHelpers

  describe '#object_link_text_extras' do
    before do
      enable_design_management(enabled)
    end

    let(:enabled) { true }
    let_it_be(:issue) { create(:issue) }

    let(:project) { issue.project }
    let(:matches) { ::Issue.link_reference_pattern.match(input_text) }
    let(:current_user) { project.owner }
    let(:extras) { subject.object_link_text_extras(issue, matches) }

    subject do
      render_context = Banzai::RenderContext.new(project, current_user)
      context = { project: project, current_user: current_user, render_context: render_context }
      described_class.new(input_text, context)
    end

    context 'the link does not go to the designs tab' do
      let(:input_text) { Gitlab::Routing.url_helpers.project_issue_url(issue.project, issue) }

      it 'does not include designs' do
        expect(extras).not_to include('designs')
      end
    end

    context 'the link goes to the designs tab' do
      let(:input_text) { url_for_designs(issue) }

      it 'includes designs' do
        expect(extras).to include('designs')
      end

      context 'design management is disabled' do
        let(:enabled) { false }

        it 'does not include designs in the extras' do
          expect(extras).not_to include('designs')
        end
      end
    end
  end
end
