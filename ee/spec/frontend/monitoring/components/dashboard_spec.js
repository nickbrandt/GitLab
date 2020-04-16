import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { GlModal, GlDeprecatedButton } from '@gitlab/ui';
import Dashboard from 'ee/monitoring/components/dashboard.vue';
import { mockApiEndpoint, propsData } from 'jest/monitoring/mock_data';
import { metricsDashboardResponse } from 'jest/monitoring/fixture_data';
import { setupStoreWithData } from 'jest/monitoring/store_utils';
import CustomMetricsFormFields from '~/custom_metrics/components/custom_metrics_form_fields.vue';
import Tracking from '~/tracking';
import { createStore } from '~/monitoring/stores';
import axios from '~/lib/utils/axios_utils';

describe('Dashboard', () => {
  let mock;
  let store;
  let wrapper;

  const findAddMetricButton = () => wrapper.vm.$refs.addMetricBtn;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(Dashboard, {
      propsData: { ...propsData, ...props },
      stubs: {
        GlDeprecatedButton,
      },
      store,
    });
  };

  beforeEach(() => {
    setFixtures(`
      <div class="prometheus-graphs"></div>
      <div class="layout-page"></div>
    `);
    window.gon = { ...window.gon, ee: true };
    store = createStore();
    mock = new MockAdapter(axios);
    mock.onGet(mockApiEndpoint).reply(200, metricsDashboardResponse);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('add custom metrics', () => {
    describe('when not available', () => {
      beforeEach(() => {
        createComponent({
          hasMetrics: true,
          customMetricsPath: '/endpoint',
        });
      });
      it('does not render add button on the dashboard', () => {
        expect(findAddMetricButton()).toBeUndefined();
      });
    });
    describe('when available', () => {
      let origPage;
      beforeEach(done => {
        jest.spyOn(Tracking, 'event').mockReturnValue();
        createComponent({
          hasMetrics: true,
          customMetricsPath: '/endpoint',
          customMetricsAvailable: true,
        });
        setupStoreWithData(wrapper.vm.$store);

        origPage = document.body.dataset.page;
        document.body.dataset.page = 'projects:environments:metrics';

        wrapper.vm.$nextTick(done);
      });
      afterEach(() => {
        document.body.dataset.page = origPage;
      });

      it('renders add button on the dashboard', () => {
        expect(findAddMetricButton()).toBeDefined();
      });

      it('uses modal for custom metrics form', () => {
        expect(wrapper.find(GlModal).exists()).toBe(true);
        expect(wrapper.find(GlModal).attributes().modalid).toBe('add-metric');
      });
      it('adding new metric is tracked', done => {
        const submitButton = wrapper.vm.$refs.submitCustomMetricsFormBtn;
        wrapper.setData({
          formIsValid: true,
        });
        wrapper.vm.$nextTick(() => {
          submitButton.$el.click();
          wrapper.vm.$nextTick(() => {
            expect(Tracking.event).toHaveBeenCalledWith(
              document.body.dataset.page,
              'click_button',
              {
                label: 'add_new_metric',
                property: 'modal',
                value: undefined,
              },
            );
            done();
          });
        });
      });

      it('renders custom metrics form fields', () => {
        expect(wrapper.find(CustomMetricsFormFields).exists()).toBe(true);
      });
    });
  });
});
