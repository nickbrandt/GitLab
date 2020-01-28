# frozen_string_literal: true

require 'spec_helper'

describe GroupsHelper do
  let(:user) { create(:user, group_view: :security_dashboard) }
  let(:group) { create(:group, :private) }

  before do
    allow(helper).to receive(:current_user) { user }
    helper.instance_variable_set(:@group, group)

    group.add_owner(user)
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
  end

  describe '#permanent_deletion_date' do
    let(:date) { 2.days.from_now }

    subject { helper.permanent_deletion_date(date) }

    before do
      stub_application_setting(deletion_adjourned_period: 5)
    end

    it 'returns the sum of the date passed as argument and the deletion_adjourned_period set in application setting' do
      expected_date = date + 5.days

      expect(subject).to eq(expected_date.strftime('%F'))
    end
  end

  describe '#remove_group_message' do
    subject { helper.remove_group_message(group) }

    context 'adjourned deletion feature is available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
      end

      it 'returns the message related to adjourned deletion' do
        expect(subject).to include("The contents of this group, its subgroups and projects will be permanently removed after")
      end
    end

    context 'adjourned deletion feature is not available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: false)
      end

      it 'returns the message related to permanent deletion' do
        expect(subject).to include("You are going to remove #{group.name}")
        expect(subject).to include("Removed groups CANNOT be restored!")
      end
    end
  end

  describe '#show_discover_group_security?' do
    using RSpec::Parameterized::TableSyntax

    where(
      gitlab_com?: [true, false],
      user?: [true, false],
      created_at: [Time.mktime(2010, 1, 20), Time.mktime(2030, 1, 20)],
      discover_security_feature_enabled?: [true, false],
      security_dashboard_feature_available?: [true, false],
      can_admin_group?: [true, false]
    )

    with_them do
      it 'returns the expected value' do
        allow(::Gitlab).to receive(:com?) { gitlab_com? }
        allow(helper).to receive(:current_user) { user? ? user : nil }
        allow(user).to receive(:created_at) { created_at }
        allow(::Feature).to receive(:enabled?).with(:discover_security) { discover_security_feature_enabled? }
        allow(group).to receive(:feature_available?) { security_dashboard_feature_available? }
        allow(helper).to receive(:can?) { can_admin_group? }

        expected_value = gitlab_com? && user? && created_at > DateTime.new(2020, 1, 20) &&
                         discover_security_feature_enabled? && !security_dashboard_feature_available? && can_admin_group?

        expect(helper.show_discover_group_security?(group)).to eq(expected_value)
      end
    end
  end
end
