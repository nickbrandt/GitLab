# frozen_string_literal: true

require 'spec_helper'

describe 'groups/edit.html.haml' do
  set(:user) { create(:user) }
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
      before do
        create(:ip_restriction, group: group, range: '192.168.0.0/24')
      end

      it 'renders ip_restriction setting' do
        render

        expect(rendered).to render_template('groups/settings/_ip_restriction')
        expect(rendered).to(have_field('group_ip_restriction_attributes_range',
                                       { disabled: false,
                                         with: '192.168.0.0/24' }))
      end
    end

    context 'subgroup' do
      let(:group) { create(:group, :nested) }

      before do
        create(:ip_restriction, group: group.parent, range: '192.168.0.0/24')
        group.build_ip_restriction
      end

      it 'show read-only ip_restriction setting of root ancestor' do
        render

        expect(rendered).to render_template('groups/settings/_ip_restriction')
        expect(rendered).to(have_field('group_ip_restriction_attributes_range',
                                       { disabled: true,
                                         with: '192.168.0.0/24' }))
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
end
