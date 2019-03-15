require 'spec_helper'

describe GroupsHelper do
  before do
    allow(helper).to receive(:current_user) { user }
  end

  let(:user) { create(:user, group_view: :security_dashboard) }
  let(:group) { create(:group, :private) }

  describe '#group_sidebar_links' do
    before do
      group.add_owner(user)
      helper.instance_variable_set(:@group, group)
      allow(helper).to receive(:can?) { |*args| Ability.allowed?(*args) }
      allow(helper).to receive(:show_promotions?) { false }
    end

    it 'shows the licensed features when they are available' do
      stub_licensed_features(contribution_analytics: true,
                             epics: true)

      expect(helper.group_sidebar_links).to include(:contribution_analytics, :epics)
    end

    it 'hides the licensed features when they are not available' do
      stub_licensed_features(contribution_analytics: false,
                             epics: false)

      expect(helper.group_sidebar_links).not_to include(:contribution_analytics, :epics)
    end
  end
end
