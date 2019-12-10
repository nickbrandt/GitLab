import Vue from 'vue';

import geoNodeActionsComponent from 'ee/geo_nodes/components/geo_node_actions.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import eventHub from 'ee/geo_nodes/event_hub';
import { NODE_ACTIONS } from 'ee/geo_nodes/constants';
import { mockNodes } from '../mock_data';

const createComponent = (
  node = mockNodes[0],
  nodeEditAllowed = true,
  nodeActionsAllowed = true,
  nodeMissingOauth = false,
) => {
  const Component = Vue.extend(geoNodeActionsComponent);

  return mountComponent(Component, {
    node,
    nodeEditAllowed,
    nodeActionsAllowed,
    nodeMissingOauth,
  });
};

describe('GeoNodeActionsComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('isToggleAllowed', () => {
      it('returns boolean value representing if toggle on node can be allowed', () => {
        let vmX = createComponent(mockNodes[0], true, false);

        expect(vmX.isToggleAllowed).toBeFalsy();
        vmX.$destroy();

        vmX = createComponent(mockNodes[1]);

        expect(vmX.isToggleAllowed).toBeTruthy();
        vmX.$destroy();
      });
    });

    describe('nodeToggleLabel', () => {
      it('returns label for toggle button for a node', () => {
        let mockNode = Object.assign({}, mockNodes[1]);
        let vmX = createComponent(mockNode);

        expect(vmX.nodeToggleLabel).toBe('Pause replication');
        vmX.$destroy();

        mockNode = Object.assign({}, mockNodes[1], { enabled: false });
        vmX = createComponent(mockNode);

        expect(vmX.nodeToggleLabel).toBe('Resume replication');
        vmX.$destroy();
      });
    });
  });

  describe('methods', () => {
    describe('onToggleNode', () => {
      it('emits showNodeActionModal with actionType `toggle`, node reference, modalMessage and modalActionLabel', () => {
        spyOn(eventHub, '$emit');
        vm.onToggleNode();

        expect(eventHub.$emit).toHaveBeenCalledWith('showNodeActionModal', {
          actionType: NODE_ACTIONS.TOGGLE,
          node: vm.node,
          modalMessage: 'Pausing replication stops the sync process.',
          modalActionLabel: vm.nodeToggleLabel,
        });
      });
    });

    describe('onRemovePrimaryNode', () => {
      it('emits showNodeActionModal with actionType `remove`, node reference, modalKind, modalMessage and modalActionLabel', () => {
        spyOn(eventHub, '$emit');
        vm.onRemovePrimaryNode();

        expect(eventHub.$emit).toHaveBeenCalledWith('showNodeActionModal', {
          actionType: NODE_ACTIONS.REMOVE,
          node: vm.node,
          modalKind: 'danger',
          modalMessage:
            'Removing a primary node stops the sync process for all nodes. Syncing cannot be resumed without losing some data on all secondaries. In this case we would recommend setting up all nodes from scratch. Are you sure?',
          modalActionLabel: 'Remove',
        });
      });
    });

    describe('onRemoveSecondaryNode', () => {
      it('emits showNodeActionModal with actionType `remove`, node reference, modalKind, modalMessage and modalActionLabel', () => {
        spyOn(eventHub, '$emit');
        vm.onRemoveSecondaryNode();

        expect(eventHub.$emit).toHaveBeenCalledWith('showNodeActionModal', {
          actionType: NODE_ACTIONS.REMOVE,
          node: vm.node,
          modalKind: 'danger',
          modalMessage:
            'Removing a secondary node stops the sync process. It is not currently possible to add back the same node without losing some data. We only recommend setting up a new secondary node in this case. Are you sure?',
          modalActionLabel: 'Remove',
        });
      });
    });

    describe('onRepairNode', () => {
      it('emits `repairNode` event with node reference', () => {
        spyOn(eventHub, '$emit');
        vm.onRepairNode();

        expect(eventHub.$emit).toHaveBeenCalledWith('repairNode', vm.node);
      });
    });
  });

  describe('template', () => {
    it('renders container elements correctly', () => {
      expect(vm.$el.classList.contains('geo-node-actions')).toBe(true);
      expect(vm.$el.querySelectorAll('.btn-sm').length).not.toBe(0);
    });
  });
});
