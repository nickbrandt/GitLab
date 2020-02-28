# frozen_string_literal: true

require 'spec_helper'

describe GroupsHelper do
  let(:owner) { create(:user, group_view: :security_dashboard) }
  let(:current_user) { owner }
  let(:group) { create(:group, :private) }

  before do
    allow(helper).to receive(:current_user) { current_user }
    helper.instance_variable_set(:@group, group)

    group.add_owner(owner)
  end

  describe '#group_epics_count' do
    before do
      stub_licensed_features(epics: true)

      create_list(:epic, 3, :opened, group: group)
      create_list(:epic, 2, :closed, group: group)
    end

    it 'returns open epics count' do
      expect(helper.group_epics_count(state: 'opened')).to eq(3)
    end

    it 'returns closed epics count' do
      expect(helper.group_epics_count(state: 'closed')).to eq(2)
    end
  end

  describe '#group_sidebar_links' do
    before do
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

    context 'when contribution analytics is available' do
      before do
        stub_licensed_features(contribution_analytics: true)
      end

      context 'signed in user is a project member but not a member of the group' do
        let(:current_user) { create(:user) }
        let(:private_project) { create(:project, :private, group: group)}

        it 'hides Contribution Analytics' do
          expect(helper.group_sidebar_links).not_to include(:contribution_analytics)
        end
      end
    end
  end
end
