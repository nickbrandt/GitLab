import Vue from 'vue';

import QuartersHeaderItemComponent from 'ee/roadmap/components/preset_quarters/quarters_header_item.vue';
import { getTimeframeForQuartersView } from 'ee/roadmap/utils/roadmap_utils';

import mountComponent from 'helpers/vue_mount_component_helper';
import { useFakeDate } from 'helpers/fake_date';
import { mockTimeframeInitialDate } from '../../mock_data';

const mockTimeframeIndex = 0;
const mockTimeframeQuarters = getTimeframeForQuartersView(mockTimeframeInitialDate);

const createComponent = ({
  timeframeIndex = mockTimeframeIndex,
  timeframeItem = mockTimeframeQuarters[mockTimeframeIndex],
  timeframe = mockTimeframeQuarters,
}) => {
  const Component = Vue.extend(QuartersHeaderItemComponent);

  return mountComponent(Component, {
    timeframeIndex,
    timeframeItem,
    timeframe,
  });
};

describe('QuartersHeaderItemComponent', () => {
  // Some parts of this spec are dependent that the current date is > 2018
  useFakeDate(2020, 6, 3);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      vm = createComponent({});
      const currentDate = new Date();

      expect(vm.currentDate.getDate()).toBe(currentDate.getDate());
    });
  });

  describe('computed', () => {
    describe('quarterBeginDate', () => {
      it('returns date object representing quarter begin date for current `timeframeItem`', () => {
        expect(vm.quarterBeginDate).toBe(mockTimeframeQuarters[mockTimeframeIndex].range[0]);
      });
    });

    describe('quarterEndDate', () => {
      it('returns date object representing quarter end date for current `timeframeItem`', () => {
        expect(vm.quarterEndDate).toBe(mockTimeframeQuarters[mockTimeframeIndex].range[2]);
      });
    });

    describe('timelineHeaderLabel', () => {
      it('returns string containing Year and Quarter for current timeline header item', () => {
        vm = createComponent({});

        expect(vm.timelineHeaderLabel).toBe('2017 Q3');
      });

      it('returns string containing only Quarter for current timeline header item when previous header contained Year', () => {
        vm = createComponent({
          timeframeIndex: mockTimeframeIndex + 2,
          timeframeItem: mockTimeframeQuarters[mockTimeframeIndex + 2],
        });

        expect(vm.timelineHeaderLabel).toBe('2018 Q1');
      });
    });

    describe('timelineHeaderClass', () => {
      it('returns empty string when timeframeItem quarter is less than current quarter', () => {
        vm = createComponent({});

        expect(vm.timelineHeaderClass).toBe('');
      });

      it('returns string containing `label-dark label-bold` when current quarter is same as timeframeItem quarter', (done) => {
        vm = createComponent({
          timeframeItem: mockTimeframeQuarters[1],
        });

        [, vm.currentDate] = mockTimeframeQuarters[1].range;
        Vue.nextTick()
          .then(() => {
            expect(vm.timelineHeaderClass).toBe('label-dark label-bold');
          })
          .then(done)
          .catch(done.fail);
      });

      it('returns string containing `label-dark` when current quarter is less than timeframeItem quarter', () => {
        const timeframeIndex = 2;
        const timeframeItem = mockTimeframeQuarters[1];
        vm = createComponent({
          timeframeIndex,
          timeframeItem,
        });

        [vm.currentDate] = mockTimeframeQuarters[0].range;

        expect(vm.timelineHeaderClass).toBe('label-dark');
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      vm = createComponent({});
    });

    it('renders component container element with class `timeline-header-item`', () => {
      expect(vm.$el.classList.contains('timeline-header-item')).toBeTruthy();
    });

    it('renders item label element class `item-label` and value as `timelineHeaderLabel`', () => {
      const itemLabelEl = vm.$el.querySelector('.item-label');

      expect(itemLabelEl).not.toBeNull();
      expect(itemLabelEl.innerText.trim()).toBe('2017 Q3');
    });
  });
});
