import stats from 'ee/stats';

export default {
  methods: {
    trackUninstallButtonClick: application => {
      stats.trackEvent('k8s_cluster', 'uninstall', {
        label: application,
      });
    },
  },
};
