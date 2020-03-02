# frozen_string_literal: true

require 'spec_helper'

describe 'layouts/nav/sidebar/_group' do
  before do
    assign(:group, group)
  end

  let(:group) { create(:group) }
  let(:user) { create(:user) }

  describe 'contribution analytics tab' do
    it 'is not visible when there is no valid license and we dont show promotions' do
      stub_licensed_features(contribution_analytics: false)

      render

      expect(rendered).not_to have_text 'Contribution Analytics'
    end

    context 'no license installed' do
      let!(:cuser) { create(:admin) }

      before do
        allow(License).to receive(:current).and_return(nil)
        stub_application_setting(check_namespace_plan: false)

        allow(view).to receive(:can?) { |*args| Ability.allowed?(*args) }
        allow(view).to receive(:current_user).and_return(cuser)
      end

      it 'is visible when there is no valid license but we show promotions' do
        stub_licensed_features(contribution_analytics: false)

        render

        expect(rendered).to have_text 'Contribution Analytics'
      end
    end

    it 'is visible' do
      stub_licensed_features(contribution_analytics: true)

      render

      expect(rendered).to have_text 'Contribution Analytics'
    end

    describe 'group issue boards link' do
      context 'when multiple issue board is disabled' do
        it 'shows link text in singular' do
          render

          expect(rendered).to have_text 'Board'
        end
      end

      context 'when multiple issue board is enabled' do
        before do
          stub_licensed_features(multiple_group_issue_boards: true)
        end

        it 'shows link text in plural' do
          render

          expect(rendered).to have_text 'Boards'
        end
      end
    end
  end

  describe 'security dashboard tab' do
    let(:group) { create(:group, plan: :gold_plan) }

    before do
      enable_namespace_license_check!

      create(:gitlab_subscription, hosted_plan: group.plan, namespace: group)
    end

    context 'when security dashboard feature is enabled' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      it 'is visible' do
        render

        expect(rendered).to have_link 'Security & Compliance'
        expect(rendered).to have_link 'Security'
      end
    end

    context 'when compliance dashboard feature is enabled' do
      before do
        stub_licensed_features(group_level_compliance_dashboard: true)
      end

      context 'when the user does not have access to Compliance dashboard' do
        it 'is not visible' do
          render

          expect(rendered).not_to have_link 'Security & Compliance'
          expect(rendered).not_to have_link 'Compliance'
        end
      end

      context 'when the user has access to Compliance dashboard' do
        before do
          group.add_owner(user)
          allow(view).to receive(:current_user).and_return(user)
        end

        it 'is visible' do
          render

          expect(rendered).to have_link 'Security & Compliance'
          expect(rendered).to have_link 'Compliance'
        end
      end
    end

    context 'when credentials inventory feature is enabled' do
      shared_examples_for 'Credentials tab is not visible' do
        it 'does not show the `Credentials` tab' do
          render

          expect(rendered).not_to have_link 'Security & Compliance'
          expect(rendered).not_to have_link 'Credentials'
        end
      end

      before do
        stub_licensed_features(credentials_inventory: true)
      end

      context 'when the group does not enforce managed accounts' do
        it_behaves_like 'Credentials tab is not visible'
      end

      context 'when the group enforces managed accounts' do
        before do
          allow(group).to receive(:enforced_group_managed_accounts?).and_return(true)
        end

        context 'when the user has privileges to view Credentials' do
          before do
            group.add_owner(user)
            allow(view).to receive(:current_user).and_return(user)
          end

          it 'is visible' do
            render

            expect(rendered).to have_link 'Security & Compliance'
            expect(rendered).to have_link 'Credentials'
          end
        end

        context 'when the user does not have privileges to view Credentials' do
          it_behaves_like 'Credentials tab is not visible'
        end
      end
    end

    context 'when security dashboard feature is disabled' do
      let(:group) { create(:group, plan: :bronze_plan) }

      it 'is not visible' do
        render

        expect(rendered).not_to have_link 'Security & Compliance'
      end
    end
  end
end
