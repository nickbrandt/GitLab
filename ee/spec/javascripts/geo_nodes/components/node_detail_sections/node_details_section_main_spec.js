import Vue from 'vue';

import NodeDetailsSectionMainComponent from 'ee/geo_nodes/components/node_detail_sections/node_details_section_main.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockNode, mockNodeDetails } from 'ee_spec/geo_nodes/mock_data';

const MOCK_VERSION_TEXT = `${mockNodeDetails.version} (${mockNodeDetails.revision})`;

const createComponent = ({
  node = Object.assign({}, mockNode),
  nodeDetails = Object.assign({}, mockNodeDetails),
  nodeActionsAllowed = true,
  nodeEditAllowed = true,
  versionMismatch = false,
}) => {
  const Component = Vue.extend(NodeDetailsSectionMainComponent);

  return mountComponent(Component, {
    node,
    nodeDetails,
    nodeActionsAllowed,
    nodeEditAllowed,
    versionMismatch,
  });
};

describe('NodeDetailsSectionMain', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent({});
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('nodeVersion', () => {
      it('returns `Unknown` when `version` and `revision` are null', done => {
        vm.nodeDetails.version = null;
        vm.nodeDetails.revision = null;
        Vue.nextTick()
          .then(() => {
            expect(vm.nodeVersion).toBe('Unknown');
          })
          .then(done)
          .catch(done.fail);
      });

      it('returns version string', () => {
        expect(vm.nodeVersion).toBe(MOCK_VERSION_TEXT);
      });
    });

    describe('nodeHealthStatus', () => {
      it('returns health status string', done => {
        // With default mock data
        expect(vm.nodeHealthStatus).toBe('Healthy');

        // With altered mock data for Unhealthy status
        vm.nodeDetails.healthStatus = 'Unhealthy';
        vm.nodeDetails.healthy = false;
        Vue.nextTick()
          .then(() => {
            expect(vm.nodeHealthStatus).toBe('Unhealthy');
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('template', () => {
    it('renders component container element', () => {
      expect(vm.$el.classList.contains('primary-section')).toBe(true);
    });

    it('renders node url element', () => {
      expect(vm.$el.querySelector('.js-node-url-title').innerText.trim()).toBe('Node URL');
      expect(vm.$el.querySelector('.js-node-url-value').innerText.trim()).toBe(vm.node.url);
    });

    it('renders node version element', () => {
      expect(vm.$el.querySelector('.js-node-version-title').innerText.trim()).toBe(
        'GitLab version',
      );

      expect(vm.$el.querySelector('.js-node-version-value').innerText.trim()).toBe(
        MOCK_VERSION_TEXT,
      );
    });
  });
});
