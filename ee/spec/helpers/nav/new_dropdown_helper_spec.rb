# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nav::NewDropdownHelper do
  describe '#new_dropdown_view_model' do
    let_it_be(:user) { build_stubbed(:user) }
    let_it_be(:group) { build_stubbed(:group) }

    let(:subject) { helper.new_dropdown_view_model(group: group, project: nil) }

    before do
      allow(helper).to receive(:current_user) { user }
      allow(helper).to receive(:can?) { false }
      allow(helper).to receive(:can?).with(user, :create_epic, group) { true }
    end

    context 'with group and can create_epic' do
      it 'shows create epic menu item' do
        expect(subject[:menu_sections][0]).to eq({
          title: 'This group',
          menu_items: [
            ::Gitlab::Nav::TopNavMenuItem.build(
              id: 'create_epic',
              title: 'New epic',
              href: "/groups/#{group.path}/-/epics/new",
              data: { track_event: 'click_link_new_epic', track_label: 'plus_menu_dropdown' }
            )
          ]
        })
      end
    end
  end
end
