# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/_compliance_frameworks.html.haml' do
  let_it_be(:group) { build(:group) }
  let(:title) { 'Compliance frameworks' }
  let(:description) { 'Configure frameworks to apply enforceable rules to projects.' }

  before do
    assign(:group, group)
  end

  context 'when the compliance frameworks should show' do
    before do
      allow(view).to receive(:show_compliance_frameworks?).and_return(true)
    end

    it 'shows the compliance frameworks list', :aggregate_failures do
      render

      expect(rendered).to have_content(title)
      expect(rendered).to have_content(description)
    end

    it 'does not link to the member list', :aggregate_failures do
      render

      expect(rendered).not_to have_content("Customizable by owners of #{group.name}.")
    end
  end

  context 'when the compliance frameworks should not show' do
    before do
      allow(view).to receive(:show_compliance_frameworks?).and_return(false)
    end

    it 'hides the compliance frameworks list', :aggregate_failures do
      render

      expect(rendered).not_to have_content(title)
      expect(rendered).not_to have_content(description)
    end
  end

  context 'when group is a subgroup' do
    let_it_be(:subgroup) { create(:group, :nested) }

    before do
      assign(:group, subgroup)
      allow(view).to receive(:show_compliance_frameworks?).and_return(true)
    end

    it 'links to the root ancestor member list', :aggregate_failures do
      render

      expect(rendered).to have_content("Customizable by owners of #{subgroup.root_ancestor.name}.")
    end
  end
end
