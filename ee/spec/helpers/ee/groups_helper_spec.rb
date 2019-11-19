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

  context 'when new Vulnerability Findings API enabled' do
    it 'returns new "vulnerability findings" endpoint paths' do
      expect(helper.group_vulnerabilities_endpoint_path(group)).to eq group_security_vulnerability_findings_path(group)
      expect(helper.group_vulnerabilities_summary_endpoint_path(group)).to eq summary_group_security_vulnerability_findings_path(group)
      expect(helper.group_vulnerabilities_history_endpoint_path(group)).to eq history_group_security_vulnerability_findings_path(group)
    end
  end

  context 'when new Vulnerability Findings API disabled' do
    before do
      stub_feature_flags(first_class_vulnerabilities: false)
    end

    it 'returns legacy "vulnerabilities" endpoint paths' do
      expect(helper.group_vulnerabilities_endpoint_path(group)).to eq group_security_vulnerabilities_path(group)
      expect(helper.group_vulnerabilities_summary_endpoint_path(group)).to eq summary_group_security_vulnerabilities_path(group)
      expect(helper.group_vulnerabilities_history_endpoint_path(group)).to eq history_group_security_vulnerabilities_path(group)
    end
  end
end
