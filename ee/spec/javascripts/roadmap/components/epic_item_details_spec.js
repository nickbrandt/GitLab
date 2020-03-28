import Vue from 'vue';

import epicItemDetailsComponent from 'ee/roadmap/components/epic_item_details.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockGroupId, mockEpic } from '../mock_data';

const createComponent = (epic = mockEpic, currentGroupId = mockGroupId) => {
  const Component = Vue.extend(epicItemDetailsComponent);

  return mountComponent(Component, {
    epic,
    currentGroupId,
    timeframeString: 'Jul 10, 2017 – Jun 2, 2018',
  });
};

describe('EpicItemDetailsComponent', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('isEpicGroupDifferent', () => {
      it('returns true when Epic.groupId is different from currentGroupId', () => {
        const mockEpicItem = Object.assign({}, mockEpic, { groupId: 1 });
        vm = createComponent(mockEpicItem, 2);

        expect(vm.isEpicGroupDifferent).toBe(true);
      });

      it('returns false when Epic.groupId is same as currentGroupId', () => {
        const mockEpicItem = Object.assign({}, mockEpic, { groupId: 1 });
        vm = createComponent(mockEpicItem, 1);

        expect(vm.isEpicGroupDifferent).toBe(false);
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `epic-details-cell`', () => {
      vm = createComponent();

      expect(vm.$el.classList.contains('epic-details-cell')).toBe(true);
    });

    it('renders Epic title correctly', () => {
      vm = createComponent();
      const epicTitleEl = vm.$el.querySelector('.epic-title .epic-url');

      expect(epicTitleEl).not.toBeNull();
      expect(epicTitleEl.getAttribute('href')).toBe(mockEpic.webUrl);
      expect(epicTitleEl.innerText.trim()).toBe(mockEpic.title);
    });

    it('renders Epic group name and tooltip', () => {
      const mockEpicItem = Object.assign({}, mockEpic, {
        groupId: 1,
        groupName: 'Bar',
        groupFullName: 'Foo / Bar',
      });
      vm = createComponent(mockEpicItem, 2);
      const epicGroupNameEl = vm.$el.querySelector('.epic-group-timeframe .epic-group');

      expect(epicGroupNameEl).not.toBeNull();
      expect(epicGroupNameEl.innerText.trim()).toContain(mockEpicItem.groupName);
      expect(epicGroupNameEl.getAttribute('title')).toBe(mockEpicItem.groupFullName);
    });

    it('renders Epic timeframe', () => {
      vm = createComponent();
      const epicTimeframeEl = vm.$el.querySelector('.epic-group-timeframe .epic-timeframe');

      expect(epicTimeframeEl).not.toBeNull();
      expect(epicTimeframeEl.innerText.trim()).toBe('Jul 10, 2017 – Jun 2, 2018');
    });
  });
});
