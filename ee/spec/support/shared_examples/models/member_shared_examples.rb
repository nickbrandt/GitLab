# frozen_string_literal: true
require 'spec_helper'

shared_examples_for 'member validations' do
  describe 'validations' do
    context 'validates SSO enforcement' do
      let(:user) { create(:user) }
      let(:identity) { create(:group_saml_identity, user: user) }
      let(:group) { identity.saml_provider.group }
      let(:entity) { group }

      before do
        stub_feature_flags(enforced_sso: true)
      end

      context 'enforced SSO enabled' do
        before do
          allow_any_instance_of(SamlProvider).to receive(:enforced_sso).and_return(true)
        end

        it 'allows adding the group member' do
          member = described_class.add_user(entity, user, Member::DEVELOPER)

          expect(member).to be_valid
        end

        it 'does not add the group member' do
          member = described_class.add_user(entity, create(:user), Member::DEVELOPER)

          expect(member).not_to be_valid
          expect(member.errors.messages[:user]).to eq(['is not linked to a SAML account'])
        end

        context 'subgroups', :nested_groups do
          let!(:subgroup) { create(:group, parent: group) }

          before do
            entity.update(group: subgroup) if entity.is_a?(Project)
          end

          it 'allows adding a group member without SSO enforced on subgroup' do
            stub_feature_flags(enforced_sso: false, group: subgroup)

            member = described_class.add_user(entity, create(:user), ProjectMember::DEVELOPER)

            expect(member).to be_valid
          end

          it 'does not allow adding a group member with SSO enforced on subgroup' do
            stub_feature_flags(enforced_sso: true, group: subgroup)

            member = described_class.add_user(entity, create(:user), ProjectMember::DEVELOPER)

            expect(member).not_to be_valid
            expect(member.errors.messages[:user]).to eq(['is not linked to a SAML account'])
          end
        end
      end

      context 'enforced SSO disabled' do
        it 'allows adding the group member' do
          member = described_class.add_user(entity, user, Member::DEVELOPER)

          expect(member).to be_valid
        end
      end
    end
  end
end
