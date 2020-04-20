import { mount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import stubChildren from 'helpers/stub_children';
import SurfaceAlertsList from '~/surface_alerts/components/surface_alerts_list.vue';

describe('SurfaceAlertsList', () => {
  let wrapper;

  function mountComponent({ stubs = {} } = {}) {
    wrapper = mount(SurfaceAlertsList, {
      propsData: {
        indexPath: '/path',
        enableSurfaceAlertsPath: '/link',
        emptyAlertSvgPath: 'illustration/path',
      },
      stubs: {
        ...stubChildren(SurfaceAlertsList),
        ...stubs,
      },
    });
  }

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('surface alert feature renders empty state', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('shows empty state', () => {
      expect(wrapper.find(GlEmptyState).exists()).toBe(true);
    });
  });
});
