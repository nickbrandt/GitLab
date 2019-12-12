import { TrackingActions } from './constants';

const trackInstallationTabChange = {
  methods: {
    trackInstallationTabChange(tabIndex) {
      const action = tabIndex === 0 ? TrackingActions.INSTALLATION : TrackingActions.REGISTRY_SETUP;
      this.track(action);
    },
  },
};

export default trackInstallationTabChange;
