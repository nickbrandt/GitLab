# frozen_string_literal: true

require 'spec_helper'

describe 'Group Dependency Proxy' do
  let(:owner) { create(:user) }
  let(:developer) { create(:user) }
  let(:group) { create(:group) }
  let(:path) { group_dependency_proxy_path(group) }

  before do
    group.add_owner(owner)
    group.add_developer(developer)
  end

  describe 'feature settings', :js do
    context 'when not logged in' do
      it 'does not show the feature settings' do
        visit path

        expect(page).not_to have_css('.js-dependency-proxy-toggle-area')
        expect(page).not_to have_css('.js-dependency-proxy-url')
      end
    end

    context 'when logged in as group owner' do
      before do
        sign_in(owner)
        visit path
      end

      it 'toggle defaults to disabled' do
        page.within('.js-dependency-proxy-toggle-area') do
          expect(find('.js-project-feature-toggle-input', visible: false).value).to eq('false')
        end
      end

      context 'when disabled' do
        it 'does not show the proxy URL' do
          expect(page).not_to have_css('.js-dependency-proxy-url')
        end
      end

      context 'when enabled by owner' do
        before do
          page.within('.edit_dependency_proxy_group_setting') do
            find('.js-project-feature-toggle').click
          end

          click_button('Save changes')
          wait_for_requests
          visit path
        end

        it 'shows the proxy URL' do
          page.within('.edit_dependency_proxy_group_setting') do
            expect(find('.js-dependency-proxy-url').value).to have_content('/dependency_proxy/containers')
          end
        end

        context 'then when logged in as group developer' do
          before do
            sign_in(developer)
            visit path
          end

          it 'does not show the feature toggle' do
            expect(page).not_to have_css('.js-dependency-proxy-toggle-area')
          end

          it 'shows the proxy URL' do
            expect(find('.js-dependency-proxy-url').value).to have_content('/dependency_proxy/containers')
          end
        end
      end
    end
  end
end