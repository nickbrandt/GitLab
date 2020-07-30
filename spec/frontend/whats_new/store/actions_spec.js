import testAction from 'helpers/vuex_action_helper';
import actions from '~/whats_new/store/actions';

describe('whats new actions', () => {
  describe('openDrawer', () => {
    it('should commit openDrawer', () => {
      testAction(actions.openDrawer, {}, {}, [{ type: 'openDrawer' }]);
    });
  });

  describe('closeDrawer', () => {
    it('should commit closeDrawer', () => {
      testAction(actions.closeDrawer, {}, {}, [{ type: 'closeDrawer' }]);
    });
  });
});
