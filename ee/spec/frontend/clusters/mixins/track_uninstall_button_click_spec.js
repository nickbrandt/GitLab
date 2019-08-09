import trackUninstallButtonClick from 'ee/clusters/mixins/track_uninstall_button_click';
import Tracking from '~/tracking';

jest.mock('~/tracking');

describe('trackUninstallButtonClickMixin', () => {
  describe('trackUninstallButtonClick', () => {
    it('tracks an event indicating which application will be uninstalled', () => {
      const application = 'ingress';

      trackUninstallButtonClick.methods.trackUninstallButtonClick(application);
      expect(Tracking.event).toHaveBeenCalledWith('k8s_cluster', 'uninstall', {
        label: application,
      });
    });
  });
});
