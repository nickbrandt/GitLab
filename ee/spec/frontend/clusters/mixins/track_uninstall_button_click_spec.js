import trackUninstallButtonClick from 'ee/clusters/mixins/track_uninstall_button_click';
import stats from 'ee/stats';

jest.mock('ee/stats');

describe('trackUninstallButtonClickMixin', () => {
  describe('trackUninstallButtonClick', () => {
    it('sends snowplow event indicating which application will be uninstalled', () => {
      const application = 'ingress';

      trackUninstallButtonClick.methods.trackUninstallButtonClick(application);
      expect(stats.trackEvent).toHaveBeenCalledWith('k8s_cluster', 'uninstall', {
        label: application,
      });
    });
  });
});
