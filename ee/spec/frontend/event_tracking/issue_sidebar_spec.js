import Tracking from '~/tracking';
import { initSidebarTracking } from 'ee/event_tracking/issue_sidebar';

describe('ee/event_tracking/issue_sidebar', () => {
  beforeEach(() => {
    setFixtures(`
    <div>
      <div class="js-issuable-sidebar">I'm an issuable sidebar</div>
    </div>
    `);
  });

  const findIssuableSidebar = () => document.querySelector('.js-issuable-sidebar');

  describe('initSidebarTracking', () => {
    beforeEach(() => {
      jest.spyOn(Tracking.prototype, 'bind');

      initSidebarTracking();
    });

    it('bind to be called with element', () => {
      expect(Tracking.prototype.bind).toHaveBeenCalledWith(findIssuableSidebar());
    });
  });
});
