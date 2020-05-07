import Vue from 'vue';

import geoNodeActionsComponent from 'ee/geo_nodes/components/geo_node_actions.vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import eventHub from 'ee/geo_nodes/event_hub';
import { NODE_ACTIONS } from 'ee/geo_nodes/constants';
import { mockNodes } from '../mock_data';

jest.mock('ee/geo_nodes/event_hub');

const createComponent = (
  node = mockNodes[0],
  nodeEditAllowed = true,
  nodeActionsAllowed = true,
  nodeRemovalAllowed = true,
  nodeMissingOauth = false,
) => {
  const Component = Vue.extend(geoNodeActionsComponent);

  return mountComponent(Component, {
    node,
    nodeEditAllowed,
    nodeActionsAllowed,
    nodeRemovalAllowed,
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
        let mockNode = { ...mockNodes[1] };
        let vmX = createComponent(mockNode);

        expect(vmX.nodeToggleLabel).toBe('Pause replication');
        vmX.$destroy();

        mockNode = { ...mockNodes[1], enabled: false };
        vmX = createComponent(mockNode);

        expect(vmX.nodeToggleLabel).toBe('Resume replication');
        vmX.$destroy();
      });
    });

    describe('disabledRemovalTooltip', () => {
      describe.each`
        nodeRemovalAllowed | tooltip
        ${true}            | ${''}
        ${false}           | ${'Cannot remove a primary node if there is a secondary node'}
      `('when nodeRemovalAllowed is $nodeRemovalAllowed', ({ nodeRemovalAllowed, tooltip }) => {
        beforeEach(() => {
          vm = createComponent(mockNodes[0], true, true, nodeRemovalAllowed, false);
        });

        it('renders the correct tooltip', () => {
          const tip = vm.$el.querySelector('div[name=disabledRemovalTooltip]');
          expect(tip.title).toBe(tooltip);
        });
      });
    });
  });

  describe('methods', () => {
    describe('onToggleNode', () => {
      it('emits showNodeActionModal with actionType `toggle`, node reference, modalMessage, modalActionLabel, and modalTitle', () => {
        vm.onToggleNode();

        expect(eventHub.$emit).toHaveBeenCalledWith('showNodeActionModal', {
          actionType: NODE_ACTIONS.TOGGLE,
          node: vm.node,
          modalMessage: 'Pausing replication stops the sync process. Are you sure?',
          modalActionLabel: vm.nodeToggleLabel,
          modalTitle: 'Pause replication',
        });
      });
    });

    describe('onRemovePrimaryNode', () => {
      it('emits showNodeActionModal with actionType `remove`, node reference, modalKind, modalMessage, modalActionLabel, and modalTitle', () => {
        vm.onRemovePrimaryNode();

        expect(eventHub.$emit).toHaveBeenCalledWith('showNodeActionModal', {
          actionType: NODE_ACTIONS.REMOVE,
          node: vm.node,
          modalKind: 'danger',
          modalMessage:
            'Removing a Geo primary node stops the synchronization to all nodes. Are you sure?',
          modalActionLabel: 'Remove node',
          modalTitle: 'Remove primary node',
        });
      });
    });

    describe('onRemoveSecondaryNode', () => {
      it('emits showNodeActionModal with actionType `remove`, node reference, modalKind, modalMessage, modalActionLabel, and modalTitle', () => {
        vm.onRemoveSecondaryNode();

        expect(eventHub.$emit).toHaveBeenCalledWith('showNodeActionModal', {
          actionType: NODE_ACTIONS.REMOVE,
          node: vm.node,
          modalKind: 'danger',
          modalMessage:
            'Removing a Geo secondary node stops the synchronization to that node. Are you sure?',
          modalActionLabel: 'Remove node',
          modalTitle: 'Remove secondary node',
        });
      });
    });

    describe('onRepairNode', () => {
      it('emits `repairNode` event with node reference', () => {
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

    describe.each`
      nodeRemovalAllowed | buttonDisabled
      ${false}           | ${true}
      ${true}            | ${false}
    `(
      `when nodeRemovalAllowed is $nodeRemovalAllowed`,
      ({ nodeRemovalAllowed, buttonDisabled }) => {
        let removeButton;

        beforeEach(() => {
          vm = createComponent(mockNodes[0], true, true, nodeRemovalAllowed, false);
          removeButton = vm.$el.querySelector('.btn-danger');
        });

        it('has the correct button text', () => {
          expect(removeButton.innerText.trim()).toBe('Remove');
        });

        it(`the button's disabled attribute should be ${buttonDisabled}`, () => {
          expect(removeButton.disabled).toBe(buttonDisabled);
        });
      },
    );
  });
});
