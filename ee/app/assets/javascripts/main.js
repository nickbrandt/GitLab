import $ from 'jquery';
import initEETrialBanner from 'ee/ee_trial_banner';
import trackNavbarEvents from 'ee/event_tracking/navbar';
import initOnboarding from 'ee/onboarding/onboarding_helper';

$(() => {
  /**
   * EE specific scripts
   */
  $('#modal-upload-trial-license').modal('show');

  // EE specific calls
  initEETrialBanner();

  trackNavbarEvents();

  initOnboarding();
});
