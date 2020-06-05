import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import { GlEmptyState } from '@gitlab/ui';
import OnDemandScansApp from 'ee/on_demand_scans/components/on_demand_scans_app.vue';

const helpPagePath = `${TEST_HOST}/application_security/dast/index#on-demand-scans`;
const emptyStateSvgPath = `${TEST_HOST}/assets/illustrations/alert-management-empty-state.svg`;

describe('OnDemandScansApp', () => {
  let wrapper;

  const findEmptyState = () => wrapper.find(GlEmptyState);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(OnDemandScansApp, {
      propsData: {
        helpPagePath,
        emptyStateSvgPath,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('empty state', () => {
    it('renders empty state', () => {
      expect(wrapper.contains(GlEmptyState)).toBe(true);
    });

    it('passes correct props to GlEmptyState', () => {
      expect(findEmptyState().props()).toMatchObject({
        svgPath: emptyStateSvgPath,
        title: 'On-demand Scans',
        primaryButtonText: 'Create new DAST scan',
        primaryButtonLink: '#',
      });
    });
  });
});
