import $ from 'jquery';
import initEETrialBanner from 'ee/ee_trial_banner';
import Stats from 'ee/stats';

$(() => {
  /**
   * EE specific scripts
   */
  $('#modal-upload-trial-license').modal('show');

  // EE specific calls
  initEETrialBanner();

  Stats.bindTrackableContainer('.navbar-gitlab', 'navbar_top');
});
