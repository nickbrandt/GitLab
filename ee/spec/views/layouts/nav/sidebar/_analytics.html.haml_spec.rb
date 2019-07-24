# frozen_string_literal: true

require 'spec_helper'

describe 'layouts/nav/sidebar/_analytics' do
  it_behaves_like 'has nav sidebar'

  context 'top-level items' do
    before do
      render
    end

    it 'has `Analytics` link' do
      expect(rendered).to have_content('Analytics')
      expect(rendered).to include(analytics_root_path)
      expect(rendered).to match(/<use xlink:href=".+?icons-.+?#log">/)
    end

    it 'has `Productivity Analytics` link' do
      expect(rendered).to have_content('Productivity Analytics')
      expect(rendered).to include(analytics_productivity_analytics_path)
      expect(rendered).to match(/<use xlink:href=".+?icons-.+?#comment">/)
    end

    it 'has `Cycle Analytics` link' do
      expect(rendered).to have_content('Cycle Analytics')
      expect(rendered).to include(analytics_cycle_analytics_path)
      expect(rendered).to match(/<use xlink:href=".+?icons-.+?#repeat">/)
    end
  end
end
