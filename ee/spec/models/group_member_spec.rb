# frozen_string_literal: true
require 'spec_helper'

describe GroupMember do
  it { is_expected.to include_module(EE::GroupMember) }

  it_behaves_like 'member validations'

  describe 'validations' do
    describe 'group domain limitations' do
      let(:group) { create(:group) }
      let(:user) { create(:user, email: 'test@gitlab.com')}
      let(:user_2) { create(:user, email: 'test@gmail.com')}

      before do
        create(:allowed_email_domain, group: group)
      end

      context 'when group has email domain feature switched on' do
        before do
          stub_licensed_features(group_allowed_email_domains: true)
        end

        it 'users email must match allowed domain email' do
          expect(build(:group_member, group: group, user: user_2)).to be_invalid
          expect(build(:group_member, group: group, user: user)).to be_valid
        end

        it 'invited email must match allowed domain email' do
          expect(build(:group_member, group: group, user: nil, invite_email: 'user@gmail.com')).to be_invalid
          expect(build(:group_member, group: group, user: nil, invite_email: 'user@gitlab.com')).to be_valid
        end

        context 'when group is subgroup' do
          let(:subgroup) { create(:group, parent: group) }

          it 'users email must match allowed domain email' do
            expect(build(:group_member, group: subgroup, user: user_2)).to be_invalid
            expect(build(:group_member, group: subgroup, user: user)).to be_valid
          end

          it 'invited email must match allowed domain email' do
            expect(build(:group_member, group: subgroup, user: nil, invite_email: 'user@gmail.com')).to be_invalid
            expect(build(:group_member, group: subgroup, user: nil, invite_email: 'user@gitlab.com')).to be_valid
          end
        end
      end

      context 'when group has email domain feature switched off' do
        it 'users email must match allowed domain email' do
          expect(build(:group_member, group: group, user: user_2)).to be_valid
          expect(build(:group_member, group: group, user: user)).to be_valid
        end

        it 'invited email must match allowed domain email' do
          expect(build(:group_member, group: group, invite_email: 'user@gmail.com')).to be_valid
          expect(build(:group_member, group: group, invite_email: 'user@gitlab.com')).to be_valid
        end
      end
    end
  end
end
