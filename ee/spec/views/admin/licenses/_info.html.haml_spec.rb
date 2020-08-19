# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/licenses/_info' do
  let_it_be(:license) { create(:license) }

  before do
    assign(:license, license)
  end

  context 'when observing licensees' do
    it 'shows "How to upgrade" link' do
      render

      expect(rendered).to have_content('Plan: Starter - How to upgrade')
      expect(rendered).to have_link('How to upgrade')
    end
  end
end
