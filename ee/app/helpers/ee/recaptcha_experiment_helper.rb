# frozen_string_literal: true

module EE
  module RecaptchaExperimentHelper
    include FlipperSessionHelper
    extend ::Gitlab::Utils::Override

    EXPERIMENT_GROWTH_RECAPTCHA_FEATURE_NAME = :experiment_growth_recaptcha

    override :show_recaptcha_sign_up?
    def show_recaptcha_sign_up?
      super && experiment_enabled_for_session?
    end

    private

    def experiment_enabled_for_session?
      # If EXPERIMENT_GROWTH_RECAPTCHA_FEATURE_NAME is not set, we should show
      # reCAPTCHA on the sign_up page
      return true unless recaptcha_sign_up_experiment_set?

      ::Feature.enabled?(EXPERIMENT_GROWTH_RECAPTCHA_FEATURE_NAME, flipper_session)
    end

    def recaptcha_sign_up_experiment_set?
      ::Feature.persisted?(recaptcha_sign_up_experiment_feature)
    end

    def recaptcha_sign_up_experiment_feature
      ::Feature.get(EXPERIMENT_GROWTH_RECAPTCHA_FEATURE_NAME)
    end
  end
end
