import { mount, createLocalVue } from '@vue/test-utils';
import GroupedBrowserPerformanceReportsApp from 'ee/reports/browser_performance_report/grouped_browser_performance_reports_app.vue';
import Api from '~/api';

jest.mock('~/api.js');

const localVue = createLocalVue();

describe('Grouped test reports app', () => {
  let wrapper;

  const mountComponent = ({ usageDataITestingWebPerformanceWidgetTotal = false } = {}) => {
    wrapper = mount(GroupedBrowserPerformanceReportsApp, {
      localVue,
      propsData: {
        status: '',
        loadingText: '',
        errorText: '',
        successText: '',
        unresolvedIssues: [{}, {}],
        resolvedIssues: [],
        neutralIssues: [],
        hasIssues: true,
      },
      provide: {
        glFeatures: {
          usageDataITestingWebPerformanceWidgetTotal,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('service ping events', () => {
    describe('when feature flag is enabled', () => {
      beforeEach(() => {
        mountComponent({ usageDataITestingWebPerformanceWidgetTotal: true });
      });

      it('tracks an event when the widget is expanded', () => {
        wrapper.find('[data-testid="report-section-expand-button"]').trigger('click');

        expect(Api.trackRedisHllUserEvent).toHaveBeenCalledWith(wrapper.vm.$options.expandEvent);
      });
    });

    describe('when feature flag is disabled', () => {
      beforeEach(() => {
        mountComponent({ usageDataITestingWebPerformanceWidgetTotal: false });
      });

      it('tracks an event when the widget is expanded', () => {
        wrapper.find('[data-testid="report-section-expand-button"]').trigger('click');

        expect(Api.trackRedisHllUserEvent).not.toHaveBeenCalled();
      });
    });
  });
});
