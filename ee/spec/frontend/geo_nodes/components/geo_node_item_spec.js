import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';

import geoNodeItemComponent from 'ee/geo_nodes/components/geo_node_item.vue';
import eventHub from 'ee/geo_nodes/event_hub';
import { mockNode, mockNodeDetails } from '../mock_data';

jest.mock('ee/geo_nodes/event_hub');

describe('GeoNodeItemComponent', () => {
  let wrapper;

  const defaultProps = {
    node: mockNode,
    primaryNode: true,
    nodeActionsAllowed: true,
    nodeEditAllowed: true,
    nodeRemovalAllowed: true,
    geoTroubleshootingHelpPath: '/foo/bar',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(geoNodeItemComponent, {
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
      expect(wrapper.vm.isNodeDetailsLoading).toBe(true);
      expect(wrapper.vm.isNodeDetailsFailed).toBe(false);
      expect(wrapper.vm.nodeHealthStatus).toBe('');
      expect(wrapper.vm.errorMessage).toBe('');
      expect(typeof wrapper.vm.nodeDetails).toBe('object');
    });
  });

  describe('computed', () => {
    let httpsNode;

    beforeEach(() => {
      // Altered mock data for secure URL
      httpsNode = Object.assign({}, mockNode, {
        id: mockNodeDetails.id,
        url: 'https://127.0.0.1:3001/',
      });

      createComponent({ node: httpsNode });
    });

    describe('showNodeDetails', () => {
      it('returns `false` if Node details are still loading', () => {
        wrapper.vm.isNodeDetailsLoading = true;

        expect(wrapper.vm.showNodeDetails).toBeFalsy();
      });

      it('returns `false` if Node details failed to load', () => {
        wrapper.vm.isNodeDetailsLoading = false;
        wrapper.vm.isNodeDetailsFailed = true;

        expect(wrapper.vm.showNodeDetails).toBeFalsy();
      });

      it('returns `true` if Node details loaded', () => {
        wrapper.vm.handleNodeDetails(mockNodeDetails);
        wrapper.vm.isNodeDetailsLoading = false;
        wrapper.vm.isNodeDetailsFailed = false;

        expect(wrapper.vm.showNodeDetails).toBeTruthy();
      });
    });
  });

  describe('methods', () => {
    describe('handleNodeDetails', () => {
      describe('with matching ID', () => {
        beforeEach(() => {
          const mockNodeSecondary = Object.assign({}, mockNode, {
            id: mockNodeDetails.id,
            primary: false,
          });

          createComponent({ node: mockNodeSecondary });
        });

        it('intializes props based on provided `nodeDetails`', () => {
          // With altered mock data with matching ID
          wrapper.vm.handleNodeDetails(mockNodeDetails);

          expect(wrapper.vm.isNodeDetailsLoading).toBeFalsy();
          expect(wrapper.vm.isNodeDetailsFailed).toBeFalsy();
          expect(wrapper.vm.errorMessage).toBe('');
          expect(wrapper.vm.nodeDetails).toBe(mockNodeDetails);
          expect(wrapper.vm.nodeHealthStatus).toBe(mockNodeDetails.health);
        });
      });

      describe('without matching ID', () => {
        it('intializes props based on provided `nodeDetails`', () => {
          // With default mock data without matching ID
          wrapper.vm.handleNodeDetails(mockNodeDetails);

          expect(wrapper.vm.isNodeDetailsLoading).toBeTruthy();
          expect(wrapper.vm.nodeDetails).not.toBe(mockNodeDetails);
          expect(wrapper.vm.nodeHealthStatus).not.toBe(mockNodeDetails.health);
        });
      });
    });

    describe('handleMounted', () => {
      it('emits `pollNodeDetails` event and passes node ID', () => {
        wrapper.vm.handleMounted();

        expect(eventHub.$emit).toHaveBeenCalledWith('pollNodeDetails', wrapper.vm.node);
      });
    });
  });

  describe('created', () => {
    it('binds `nodeDetailsLoaded` event handler', () => {
      expect(eventHub.$on).toHaveBeenCalledWith('nodeDetailsLoaded', expect.any(Function));
    });
  });

  describe('beforeDestroy', () => {
    it('unbinds `nodeDetailsLoaded` event handler', () => {
      wrapper.destroy();

      expect(eventHub.$off).toHaveBeenCalledWith('nodeDetailsLoaded', expect.any(Function));
    });
  });

  describe('template', () => {
    it('renders container element', () => {
      expect(wrapper.vm.$el.classList.contains('card', 'geo-node-item')).toBe(true);
    });

    describe('with error', () => {
      let err;

      beforeEach(() => {
        err = 'Something error message';
        wrapper.setData({ errorMessage: err, isNodeDetailsFailed: true });
      });

      it('renders node error message', () => {
        const findErrorMessage = () => wrapper.find('.bg-danger-100');

        expect(findErrorMessage().exists()).toBeTruthy();
        expect(findErrorMessage().text()).toContain(err);
        expect(
          findErrorMessage()
            .find(GlLink)
            .attributes('href'),
        ).toBe('/foo/bar');
      });
    });
  });
});
