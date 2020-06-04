# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OnboardingExperimentHelper, type: :helper do
  using RSpec::Parameterized::TableSyntax

  describe '.allow_access_to_onboarding?' do
    context "when we're not gitlab.com" do
      it 'returns false' do
        allow(::Gitlab).to receive(:com?).and_return(false)

        expect(helper.allow_access_to_onboarding?).to be(false)
      end
    end

    context "when we're gitlab.com" do
      before do
        allow(::Gitlab).to receive(:com?).and_return(true)
      end

      context 'and the :user_onboarding feature is not enabled' do
        it 'returns false' do
          stub_feature_flags(user_onboarding: false)

          expect(helper.allow_access_to_onboarding?).to be(false)
        end
      end

      context 'and the :user_onboarding feature is enabled' do
        before do
          stub_feature_flags(user_onboarding: true)
        end

        context 'but there is no current_user' do
          it 'returns true' do
            allow(helper).to receive(:current_user).and_return(nil)

            expect(helper.allow_access_to_onboarding?).to be(true)
          end
        end

        context 'and there is a current_user' do
          let!(:user) { create(:user, id: 2) }

          before do
            allow(helper).to receive(:current_user).and_return(user)
          end

          context 'but experiment_growth_onboarding has not been set' do
            it 'returns true' do
              expect(helper.allow_access_to_onboarding?).to be(true)
            end
          end

          context 'and experiment_growth_onboarding has been set' do
            it 'checks if feature is enabled for current_user' do
              Feature.enable_percentage_of_actors(
                described_class::EXPERIMENT_GROWTH_ONBOARDING_FEATURE_NAME, 50)

              expect(helper.allow_access_to_onboarding?).to eq(true)
            end
          end
        end
      end
    end
  end
end
