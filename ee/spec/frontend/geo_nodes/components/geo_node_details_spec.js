import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';

import geoNodeDetailsComponent from 'ee/geo_nodes/components/geo_node_details.vue';
import { mockNode, mockNodeDetails } from '../mock_data';

describe('GeoNodeDetailsComponent', () => {
  let wrapper;

  const defaultProps = {
    node: mockNode,
    nodeDetails: mockNodeDetails,
    nodeActionsAllowed: true,
    nodeEditAllowed: true,
    geoTroubleshootingHelpPath: '/foo/bar',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(geoNodeDetailsComponent, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(wrapper.vm.showAdvanceItems).toBeFalsy();
      expect(wrapper.vm.errorMessage).toBe('');
    });
  });

  describe('computed', () => {
    describe('hasError', () => {
      beforeEach(() => {
        const nodeDetails = Object.assign({}, mockNodeDetails, {
          health: 'Something went wrong.',
          healthy: false,
        });

        createComponent({ nodeDetails });
      });

      it('returns boolean value representing if node has any errors', () => {
        // With altered mock data for Unhealthy status
        expect(wrapper.vm.errorMessage).toBe('Something went wrong.');
        expect(wrapper.vm.hasError).toBeTruthy();

        // With default mock data
        expect(defaultProps.hasError).toBeFalsy();
      });
    });

    describe('hasVersionMismatch', () => {
      beforeEach(() => {
        const nodeDetails = Object.assign({}, mockNodeDetails, {
          primaryVersion: '10.3.0-pre',
          primaryRevision: 'b93c51850b',
        });

        createComponent({ nodeDetails });
      });

      it('returns boolean value representing if node has version mismatch', () => {
        // With altered mock data for version mismatch
        expect(wrapper.vm.errorMessage).toBe(
          'GitLab version does not match the primary node version',
        );
        expect(wrapper.vm.hasVersionMismatch).toBeTruthy();

        // With default mock data
        expect(defaultProps.hasVersionMismatch).toBeFalsy();
      });
    });
  });

  describe('template', () => {
    it('renders container elements correctly', () => {
      expect(wrapper.vm.$el.classList.contains('card-body')).toBe(true);
    });

    describe('with error', () => {
      beforeEach(() => {
        createComponent({
          errorMessage: 'Foobar',
          nodeDetails: {
            ...defaultProps.nodeDetails,
            healthy: false,
          },
        });
      });

      it('renders troubleshooting URL within error message section', () => {
        expect(
          wrapper
            .find('.bg-danger-100')
            .find(GlLink)
            .attributes('href'),
        ).toBe('/foo/bar');
      });
    });
  });
});
