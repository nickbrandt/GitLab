import Vue from 'vue';

import SidebarLabels from 'ee/epic/components/sidebar_items/sidebar_labels.vue';
import createStore from 'ee/epic/store';

import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { mockEpicMeta, mockEpicData, mockLabels } from '../../mock_data';

describe('SidebarLabelsComponent', () => {
  let vm;
  let store;

  beforeEach(done => {
    const Component = Vue.extend(SidebarLabels);
    store = createStore();
    store.dispatch('setEpicMeta', mockEpicMeta);
    store.dispatch('setEpicData', mockEpicData);

    vm = mountComponentWithStore(Component, {
      store,
      props: { canUpdate: false, sidebarCollapsed: false },
    });

    setTimeout(done);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(vm.sidebarExpandedOnClick).toBe(false);
    });
  });

  describe('computed', () => {
    describe('epicContext', () => {
      it('returns object containing `this.labels` as a child prop', () => {
        expect(vm.epicContext.labels).toBe(vm.labels);
      });
    });
  });

  describe('methods', () => {
    describe('toggleSidebarRevealLabelsDropdown', () => {
      it('calls `toggleSidebar` action with param `sidebarCollapse`', () => {
        spyOn(vm, 'toggleSidebar');

        vm.toggleSidebarRevealLabelsDropdown();

        expect(vm.toggleSidebar).toHaveBeenCalledWith(
          jasmine.objectContaining({
            sidebarCollapsed: false,
          }),
        );
      });
    });

    describe('handleDropdownClose', () => {
      it('calls `toggleSidebar` action only when `sidebarExpandedOnClick` prop is true', () => {
        spyOn(vm, 'toggleSidebar');

        vm.sidebarExpandedOnClick = true;

        vm.handleDropdownClose();

        expect(vm.sidebarExpandedOnClick).toBe(false);
        expect(vm.toggleSidebar).toHaveBeenCalledWith(
          jasmine.objectContaining({
            sidebarCollapsed: false,
          }),
        );
      });
    });

    describe('handleLabelClick', () => {
      const label = {
        id: 1,
        title: 'Foo',
        color: ['#BADA55'],
        text_color: '#FFFFFF',
      };

      beforeEach(() => {
        store.state.labels = mockLabels;
      });

      it('initializes `epicContext.labels` as empty array when `label.isAny` is `true`', () => {
        const labelIsAny = { isAny: true };
        vm.handleLabelClick(labelIsAny);

        expect(Array.isArray(vm.epicContext.labels)).toBe(true);
        expect(vm.epicContext.labels.length).toBe(0);
      });

      it('adds provided `label` to epicContext.labels', () => {
        vm.handleLabelClick(label);
        // epicContext.labels gets initialized with initialLabels, hence
        // newly insert label will be at second position (index `1`)
        expect(vm.epicContext.labels.length).toBe(2);
        expect(vm.epicContext.labels[1].id).toBe(label.id);
        vm.handleLabelClick(label);
      });

      it('filters epicContext.labels to exclude provided `label` if it is already present in `epicContext.labels`', () => {
        vm.handleLabelClick(label); // Select
        vm.handleLabelClick(label); // Un-select

        expect(vm.epicContext.labels.length).toBe(1);
        expect(vm.epicContext.labels[0].id).toBe(mockLabels[0].id);
      });
    });
  });

  describe('template', () => {
    it('renders labels select element container', () => {
      expect(vm.$el.classList.contains('js-labels-block')).toBe(true);
    });
  });
});
