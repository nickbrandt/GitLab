# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/edit.html.haml' do
  let_it_be(:user) { create(:user) }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)

    assign(:group, group)
    allow(view).to receive(:current_user) { user }
  end

  context 'ip_restriction' do
    before do
      stub_licensed_features(group_ip_restriction: true)
    end

    context 'top-level group' do
      shared_examples 'renders ip_restriction setting' do
        it 'renders ranges in comma separated format' do
          render

          expect(rendered).to render_template('groups/settings/_ip_restriction')
          expect(rendered).to(have_field('group_ip_restriction_ranges',
                                         { disabled: false,
                                           with: ranges.join(",") }))
        end
      end

      before do
        ranges.each do |range|
          create(:ip_restriction, group: group, range: range)
        end
      end

      context 'with single subnet' do
        let(:ranges) { ['192.168.0.0/24'] }

        it_behaves_like 'renders ip_restriction setting'
      end

      context 'with multiple subnets' do
        let(:ranges) { ['192.168.0.0/24', '192.168.1.0/8'] }

        it_behaves_like 'renders ip_restriction setting'
      end
    end

    context 'subgroup' do
      let(:group) { create(:group, :nested) }

      it 'does not show ip_restriction setting' do
        render

        expect(rendered).to render_template('groups/settings/_ip_restriction')
        expect(rendered).not_to have_field('group_ip_restriction_attributes_range')
      end
    end

    context 'feature is disabled' do
      before do
        stub_licensed_features(group_ip_restriction: false)
      end

      it 'does not show ip_restriction setting' do
        render

        expect(rendered).to render_template('groups/settings/_ip_restriction')
        expect(rendered).not_to have_field('group_ip_restriction_attributes_range')
      end
    end
  end

  context 'allowed_email_domain' do
    before do
      allow(group).to receive(:feature_available?).and_return(false)
      allow(group).to receive(:feature_available?).with(:group_allowed_email_domains).and_return(true)
    end

    context 'top-level group' do
      before do
        create(:allowed_email_domain, group: group)
      end

      it 'renders allowed_email_domain setting' do
        render

        expect(rendered).to render_template('groups/settings/_allowed_email_domain')
        expect(rendered).to(have_field('group_allowed_email_domain_attributes_domain',
                                       { disabled: false,
                                         with: 'gitlab.com' }))
      end
    end

    context 'subgroup' do
      let(:group) { create(:group, :nested) }

      it 'does not show allowed_email_domain setting' do
        render

        expect(rendered).to render_template('groups/settings/_allowed_email_domain')
        expect(rendered).not_to have_field('group_allowed_email_domain_attributes_domain')
      end
    end

    context 'feature is disabled' do
      before do
        stub_licensed_features(group_allowed_email_domains: false)
      end

      it 'does not show allowed_email_domain setting' do
        render

        expect(rendered).to render_template('groups/settings/_allowed_email_domain')
        expect(rendered).not_to have_field('group_allowed_email_domain_attributes_domain')
      end
    end
  end
end
