# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/preferences/show' do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { build(:user) }

  before do
    assign(:user, user)
    allow(controller).to receive(:current_user).and_return(user)
  end

  context 'navigation theme' do
    before do
      render
    end

    it 'has an id for anchoring' do
      expect(rendered).to have_css('#navigation-theme')
    end

    it 'has correct stylesheet tags' do
      Gitlab::Themes.each do |theme|
        next unless theme.css_filename

        expect(rendered).to have_selector("link[href*=\"themes/#{theme.css_filename}\"]", visible: false)
      end
    end
  end

  context 'syntax highlighting theme' do
    before do
      render
    end

    it 'has an id for anchoring' do
      expect(rendered).to have_css('#syntax-highlighting-theme')
    end
  end
end
