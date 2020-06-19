# frozen_string_literal: true

require 'spec_helper'

describe 'layouts/header/_new_dropdown' do
  let(:user) { create(:user) }

  context 'group-specific links' do
    let(:group) { create(:group) }

    before do
      allow(view).to receive(:current_user).and_return(user)

      assign(:group, group)
    end

    it 'does not have "New epic" link' do
      render

      expect(rendered).not_to have_link(
        'New epic',
        href: new_group_epic_path(group)
      )
    end

    context 'as a Group owner' do
      before do
        group.add_owner(user)
      end

      it 'does not have "New epic" link' do
        render

        expect(rendered).not_to have_link(
          'New epic',
          href: new_group_epic_path(group)
        )
      end

      context 'when epics are enabled' do
        before do
          stub_licensed_features(epics: true)
          stub_feature_flags(create_epic_form: true)
        end

        it 'has a "New epic" link' do
          render

          expect(rendered).to have_link(
            'New epic',
            href: new_group_epic_path(group)
          )
        end
      end
    end
  end
end
