import { shallowMount } from '@vue/test-utils';

import RoadmapItem from 'ee/roadmap/components/roadmap_item.vue';

import { PRESET_TYPES, MONTH } from 'ee/roadmap/constants';

import { mockMonthly } from 'ee_jest/roadmap/mock_data';

import { createMockEpic } from 'ee_jest/roadmap/mock_helper';

import {
  presetTypeTestCases,
  timeframeStringTestCases,
  timeframeItemTestCases,
  timelineBarTestCases,
} from 'ee_jest/roadmap/roadmap_item_test_cases';

describe('RoadmapItem component', () => {
  let wrapper;

  let defaultTimeframe;
  let defaultInitialStartDate;
  let defaultInitialEndDate;
  let defaultMockItem;

  const createWrapper = ({
    presetType = PRESET_TYPES.MONTHS,
    item = defaultMockItem, // Reminder: item can be either an epic or milestone.
    timeframe = defaultTimeframe,
  } = {}) => {
    const options = {
      propsData: {
        presetType,
        item,
        timeframe,
      },
    };

    wrapper = shallowMount(RoadmapItem, options);
  };

  beforeEach(() => {
    defaultTimeframe = mockMonthly.timeframe;
    defaultInitialStartDate = new Date(2020, MONTH.NOV, 10);
    defaultInitialEndDate = new Date(2021, MONTH.FEB, 28);
    defaultMockItem = createMockEpic({
      startDate: defaultInitialStartDate,
      endDate: defaultInitialEndDate,
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('computed', () => {
    describe.each(presetTypeTestCases)('%s', (computedPropName, presetType, timeframe) => {
      beforeEach(() => {
        createWrapper({ presetType, timeframe });
      });

      it(`returns true when presetType is PRESET_TYPE.${presetType}`, () => {
        expect(wrapper.vm[computedPropName]).toBe(true);
      });
    });

    describe('startDate', () => {
      /*
        Some clarification on "startDate" computed prop:

        Suppose an epic starts on Feb 1, 2020
        but the timeframe that can be loaded into a browser view
        only covers the period of Oct 1, 2020 ~ May 31, 2021.

        When this epic is fetched in vuex, because its start date is out-of-range
        for the timeframe, the following happens:
        
        1. startDateOutOfRange is set to true.
        2. startDate is set to the beginning of the timeframe, Oct 1, 2020.
        3. originalStartDate is set to Feb 1, 2020.

        "startDate" computed prop always returns the true, unmodified start date "Feb 1, 2020"
      */
      it('returns item.startDate when start date is within range', () => {
        const item = createMockEpic({ startDate: new Date(2020, MONTH.OCT, 1) });
        createWrapper({ item });

        expect(wrapper.vm.startDate).toEqual(item.startDate);
      });

      it('returns item.originalStartDate when start date is out of range', () => {
        // mockMonthlyTimeframe ranges from Oct 2020 to May 2021 (inclusive).
        // Set startDate to Feb 2020 to test the scenario.
        const item = createMockEpic({ startDate: new Date(2020, MONTH.FEB, 1) });
        createWrapper({ item });

        expect(wrapper.vm.startDate).toEqual(item.originalStartDate);
      });
    });

    describe('endDate', () => {
      it('returns item.endDate when end date is within range', () => {
        const item = createMockEpic({ endDate: new Date(2020, MONTH.DEC, 31) });
        createWrapper({ item });

        expect(wrapper.vm.endDate).toEqual(item.endDate);
      });

      it('returns item.originalEndDate when end date is out of range', () => {
        // mockMonthlyTimeframe ranges from Oct 2020 to May 2021 (inclusive).
        // Set endDate to Jun 2020 to test the scenario.
        const item = createMockEpic({ endDate: new Date(2021, MONTH.JUN, 1) });
        createWrapper({ item });

        expect(wrapper.vm.endDate).toEqual(item.originalEndDate);
      });
    });

    describe.each(timeframeStringTestCases)(
      'timeframeString',
      ({ when, propsData, expected, returnCondition }) => {
        describe(`when ${when}`, () => {
          beforeEach(() => {
            createWrapper({ ...propsData });
          });

          it(`returns timeframe string correctly${returnCondition}`, () => {
            expect(wrapper.vm.timeframeString).toEqual(expected.timeframeString);
          });
        });
      },
    );

    describe.each(timeframeItemTestCases)(
      'timeframeItemIndex and timeframeItem',
      ({ view, propsData, expected }) => {
        describe(`under ${view} view`, () => {
          beforeEach(() => {
            createWrapper({ ...propsData });
          });

          it('return correct values for the given epic', () => {
            expect(wrapper.vm.timeframeItemIndex).toBe(expected.timeframeItemIndex);
            expect(wrapper.vm.timeframeItem).toEqual(expected.timeframeItem);
          });
        });
      },
    );

    // Note: rendered dom elements are tested in "epic_item_spec.js"
    describe.each(timelineBarTestCases)('timelineBarStyle', ({ when, propsData, expected }) => {
      describe(`when ${when}`, () => {
        beforeEach(() => {
          createWrapper({ ...propsData });
        });

        it('returns correct epic timeline bar style', () => {
          expect(wrapper.vm.timelineBarStyle).toEqual({
            width: expected.width,
            left: expected.left,
          });
        });
      });
    });
  });
});
