import 'bootstrap/js/dist/modal';
import initEETrialBanner from 'ee/ee_trial_banner';
import trackNavbarEvents from 'ee/event_tracking/navbar';
import initNamespaceStorageLimitAlert from 'ee/namespace_storage_limit_alert';

// EE specific calls
initEETrialBanner();
initNamespaceStorageLimitAlert();

trackNavbarEvents();
