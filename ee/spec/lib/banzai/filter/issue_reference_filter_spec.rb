# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Filter::IssueReferenceFilter do
  include FilterSpecHelper
  include DesignManagementTestHelpers

  let_it_be(:issue) { create(:issue) }
  let_it_be(:project) { issue.project }
  let_it_be(:current_user) { project.owner }
  let_it_be(:designs_tab_url) { url_for_designs(issue) }

  context 'when processing a link to the designs tab' do
    before do
      enable_design_management
    end

    let(:input_text) { "See #{designs_tab_url}" }

    subject(:link) { reference_filter(input_text).css('a').first }

    it 'includes the word "designs" after the reference in the text content', :aggregate_failures do
      expect(link.attr('title')).to eq(issue.title)
      expect(link.attr('href')).to eq(designs_tab_url)
      expect(link.text).to eq("#{issue.to_reference} (designs)")
    end
  end

  describe '#object_link_text_extras' do
    before do
      enable_design_management(enabled)
    end

    let(:enabled) { true }

    let(:matches) { ::Issue.link_reference_pattern.match(input_text) }
    let(:extras) { subject.object_link_text_extras(issue, matches) }

    subject { filter_instance }

    context 'the link does not go to the designs tab' do
      let(:input_text) { Gitlab::Routing.url_helpers.project_issue_url(issue.project, issue) }

      it 'does not include designs' do
        expect(extras).not_to include('designs')
      end
    end

    context 'the link goes to the designs tab' do
      let(:input_text) { designs_tab_url }

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
