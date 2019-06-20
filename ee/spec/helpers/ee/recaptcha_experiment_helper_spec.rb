# frozen_string_literal: true

require 'spec_helper'

describe RecaptchaExperimentHelper, type: :helper do
  using RSpec::Parameterized::TableSyntax

  describe '.show_recaptcha_sign_up?' do
    context 'when reCAPTCHA is disabled' do
      it 'returns false' do
        stub_application_setting(recaptcha_enabled: false)

        expect(helper.show_recaptcha_sign_up?).to be(false)
      end
    end

    context 'when reCAPTCHA is enabled' do
      before do
        stub_application_setting(recaptcha_enabled: true)
      end

      context 'and experiment_growth_recaptcha has not been set' do
        it 'returns true' do
          expect(helper.show_recaptcha_sign_up?).to be(true)
        end
      end

      context 'and experiment_growth_recaptcha has been set' do
        let(:feature_name) { described_class::EXPERIMENT_GROWTH_RECAPTCHA_FEATURE_NAME }

        before(:all) do
          # We need to create a '50%' of actors feature flag before _any_ test
          # runs and need to continue to use the same feature throughout the
          # test duration.
          fifty_percent = ::Feature.flipper.actors(50)
          ::Feature.flipper[described_class::EXPERIMENT_GROWTH_RECAPTCHA_FEATURE_NAME].enable(fifty_percent)
        end

        after(:all) do
          Feature.flipper.remove(described_class::EXPERIMENT_GROWTH_RECAPTCHA_FEATURE_NAME)
        end

        where(:flipper_session_id, :expected_result) do
          '00687625-667c-480c-ae2a-9bf861ddd909' | true
          'b8b78156-f7b8-4bf4-b906-06a899b84ea3' | false
          'e622a262-6e48-41ba-b19f-2d91c24f17a3' | true
          'd2c0aae1-bc08-4000-bbb2-0dd2802f67e2' | false
        end

        with_them do
          it "returns expected_result" do
            allow(Feature).to receive(:enabled?).and_call_original # Allow Feature to _really_ work.
            allow(helper).to receive(:flipper_session).and_return(FlipperSession.new(flipper_session_id))

            expect(helper.show_recaptcha_sign_up?).to eq(expected_result)
          end
        end
      end
    end
  end
end
